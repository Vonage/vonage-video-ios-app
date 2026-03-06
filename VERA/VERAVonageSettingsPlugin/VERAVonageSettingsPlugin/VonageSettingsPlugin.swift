//
//  Created by Vonage on 25/2/26.
//

import Combine
import Foundation
import VERADomain
import VERASettings
import VERAVonage

/// Bridges the settings feature with the active Vonage call lifecycle.
///
/// `VonageSettingsPlugin` is a call-lifecycle plugin that:
///
/// 1. **Stats relay** – Observes the `senderStatsEnabled` flag from
///    ``PublisherSettingsRepository/preferencesPublisher`` and tells the
///    ``CallFacade`` to enable or disable SDK-level network statistics collection.
/// 2. **Stats forwarding** – Subscribes to ``CallFacade/networkStatsPublisher``
///    and writes every update to the ``StatsWriter`` so that downstream view
///    models can display real-time metrics.
/// 3. **Publisher settings relay** – Observes changes to resolution, frame rate, codec,
///    audio bitrate, and audio fallback. When any of these SDK-level settings change,
///    triggers ``CallFacade/applyPublisherSettings(_:)`` which performs a republish
///    cycle to apply the new configuration.
///
/// All subscriptions are established when the call starts and torn down when it ends.
///
/// ## Lifecycle
/// ```
/// callDidStart   ──► initObservers()
///                       ├─ subscribe to senderStatsEnabled → enable/disable stats
///                       ├─ subscribe to SDK-relevant prefs → applyPublisherSettings
///                       └─ subscribe to call.networkStatsPublisher → statsWriter
///
/// callDidEnd     ──► cancelObservables()
///                       ├─ clear stats via statsWriter
///                       └─ cancel all Combine subscriptions
/// ```
///
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallHolder``, ``StatsWriter``
public final class VonageSettingsPlugin: VonagePlugin, VonagePluginCallHolder {

    private var cancellables = Set<AnyCancellable>()
    /// Tracks the in-flight publisher-settings Task so it can be cancelled if new
    /// settings arrive before the previous republish cycle finishes.
    private var applySettingsTask: Task<Void, Never>?

    /// The active call façade, injected by the plugin coordinator.
    public weak var call: (any CallFacade)?

    /// Reactive source of publisher settings preferences (includes `senderStatsEnabled`).
    private let settingsRepository: PublisherSettingsRepository

    /// Write-only entry point for pushing live network stats to the settings module.
    private let statsWriter: StatsWriter

    /// A stable identifier for this plugin instance.
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new settings plugin.
    ///
    /// - Parameters:
    ///   - settingsRepository: Repository providing reactive preferences with the stats toggle.
    ///   - statsWriter: Writer for forwarding network stats to the settings data layer.
    public init(
        settingsRepository: PublisherSettingsRepository,
        statsWriter: StatsWriter
    ) {
        self.settingsRepository = settingsRepository
        self.statsWriter = statsWriter
    }

    // MARK: - VonagePluginCallLifeCycle

    /// Called when the call starts and the Vonage session is connected.
    ///
    /// Sets up Combine subscriptions to bridge settings preferences with the call.
    ///
    /// - Parameter userInfo: Contextual info passed by the plugin coordinator (unused).
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        initObservers()
    }

    /// Called when the call ends and the Vonage session is disconnecting.
    ///
    /// Clears stats data and cancels all subscriptions.
    public func callDidEnd() async throws {
        cancelObservables()
    }

    // MARK: - Private

    private func initObservers() {
        // Observe the sender stats toggle and enable/disable network stats collection.
        settingsRepository.preferencesPublisher
            .map(\.senderStatsEnabled)
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }
                if isEnabled {
                    self.call?.enableNetworkStats()
                } else {
                    self.call?.disableNetworkStats()
                }
            }
            .store(in: &cancellables)

        // Observe SDK-relevant preference changes and trigger a republish.
        // Maps to PublisherAdvancedSettings BEFORE removeDuplicates so that changes
        // to fields not reflected in PublisherAdvancedSettings (e.g. senderStatsEnabled)
        // do not trigger a spurious publisher recreation. dropFirst skips the initial
        // value (settings are already applied at publisher creation time via JoinRoomUseCase).
        settingsRepository.preferencesPublisher
            .map { $0.toPublisherAdvancedSettings() }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] settings in
                guard let self, let call = self.call else { return }
                // Cancel any in-flight republish cycle before starting a new one so
                // the latest settings always win and the overlay can't get stuck.
                self.applySettingsTask?.cancel()
                self.applySettingsTask = Task { [weak call] in
                    try? await call?.applyPublisherAdvancedSettings(settings)
                }
            }
            .store(in: &cancellables)

        // Forward network stats from the call to the settings data layer.
        call?.networkStatsPublisher
            .sink { [weak self] stats in
                guard let self else { return }
                self.updateStats(stats)
            }
            .store(in: &cancellables)
    }

    private func updateStats(_ stats: NetworkMediaStats) {
        Task {
            await statsWriter.updateStats(stats)
        }
    }

    private func clearStats() {
        Task {
            await statsWriter.clearStats()
        }
    }

    private func cancelObservables() {
        clearStats()
        applySettingsTask?.cancel()
        applySettingsTask = nil
        cancellables.removeAll()
    }
}
