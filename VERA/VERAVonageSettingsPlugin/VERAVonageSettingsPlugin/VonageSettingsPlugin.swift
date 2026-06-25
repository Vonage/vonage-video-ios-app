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
/// 1. **Stats relay** – Keeps SDK-level network statistics collection enabled so
///    publisher stats remain available, and uses `senderStatsEnabled` to toggle
///    the richer subscriber-only stats requests.
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
///                       ├─ enable network stats collection
///                       ├─ subscribe to senderStatsEnabled → enable/disable subscriber extras
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
    /// Tracks live publisher updates independently from publisher recreation.
    private var updateLiveSettingsTask: Task<Void, Never>?
    /// Invalidates live-update tasks whose repository emissions arrive out of order.
    private var liveSettingsGeneration = 0
    /// Tracks the stats-forwarding Task so it can be cancelled on call end.
    private var statsTask: Task<Void, Never>?

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
        call?.enableNetworkStats()
        let currentPreferences = await settingsRepository.getPreferences()
        if currentPreferences.senderStatsEnabled {
            call?.enableSubscriberExtraStats()
        } else {
            call?.disableSubscriberExtraStats()
        }
    }

    /// Called when the call ends and the Vonage session is disconnecting.
    ///
    /// Clears stats data and cancels all subscriptions.
    public func callDidEnd() async throws {
        await cancelObservables()
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
                    self.call?.enableSubscriberExtraStats()
                } else {
                    self.call?.disableSubscriberExtraStats()
                }
            }
            .store(in: &cancellables)

        // Observe settings that require recreating the publisher. Live-updatable
        // fields are intentionally ignored by the duplicate comparison.
        settingsRepository.preferencesPublisher
            .map { $0.toPublisherAdvancedSettings() }
            .removeDuplicates(by: { $0.hasEqualRepublishSettings(to: $1) })
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

        // Apply bitrate and degradation changes directly to the active publisher.
        settingsRepository.preferencesPublisher
            .map { $0.toPublisherAdvancedSettings() }
            .removeDuplicates(by: { $0.hasEqualLiveSettings(to: $1) })
            .dropFirst()
            .sink { [weak self] settings in
                guard let self, let call = self.call else { return }
                self.liveSettingsGeneration += 1
                let generation = self.liveSettingsGeneration
                self.updateLiveSettingsTask?.cancel()
                self.updateLiveSettingsTask = Task { [weak self, weak call] in
                    guard let self,
                        !Task.isCancelled,
                        self.liveSettingsGeneration == generation
                    else { return }
                    await call?.updateLivePublisherAdvancedSettings(settings)
                }
            }
            .store(in: &cancellables)

        // Forward network stats from the call to the settings data layer.
        // Uses a stored Task with `for await` so that each `statsWriter.updateStats`
        // call completes before processing the next value, avoiding fire-and-forget races.
        if let publisher = call?.networkStatsPublisher {
            statsTask = Task { [weak self] in
                for await stats in publisher.values {
                    guard let self else { return }
                    await self.statsWriter.updateStats(stats)
                }
            }
        }
    }

    private func cancelObservables() async {
        statsTask?.cancel()
        statsTask = nil
        applySettingsTask?.cancel()
        applySettingsTask = nil
        liveSettingsGeneration += 1
        updateLiveSettingsTask?.cancel()
        updateLiveSettingsTask = nil
        cancellables.removeAll()
        await statsWriter.clearStats()
    }
}

extension PublisherAdvancedSettings {
    fileprivate func hasEqualLiveSettings(to other: Self) -> Bool {
        videoBitratePreset == other.videoBitratePreset
            && maxVideoBitrate == other.maxVideoBitrate
            && degradationPreference == other.degradationPreference
    }

    fileprivate func hasEqualRepublishSettings(to other: Self) -> Bool {
        videoResolution == other.videoResolution
            && videoFrameRate == other.videoFrameRate
            && preferredVideoCodecs == other.preferredVideoCodecs
            && maxAudioBitrate == other.maxAudioBitrate
            && publisherAudioFallbackEnabled == other.publisherAudioFallbackEnabled
            && subscriberAudioFallbackEnabled == other.subscriberAudioFallbackEnabled
            && opusDtxEnabled == other.opusDtxEnabled
    }
}
