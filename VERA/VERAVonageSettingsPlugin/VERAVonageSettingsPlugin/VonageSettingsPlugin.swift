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
///    and forwards received snapshots to the ``StatsWriter`` so that downstream view
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
///                       ├─ cancel subscriptions and stats forwarding
///                       ├─ await an in-flight stats write
///                       └─ clear stats before the next source starts
/// ```
///
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallHolder``, ``StatsWriter``
@MainActor
public final class VonageSettingsPlugin: VonagePlugin, VonagePluginCallHolder {

    private var cancellables = Set<AnyCancellable>()
    /// One observation lifetime per call; late callbacks and suspended reads must match it.
    private var isStarted = false
    private var lifecycleGeneration: UInt64 = 0
    /// A replacement call cannot install observers until the previous teardown finishes.
    private var teardownTask: Task<Void, Never>?
    /// Tracks the in-flight publisher-settings Task so it can be cancelled if new
    /// settings arrive before the previous republish cycle finishes.
    private var applySettingsTask: Task<Void, Never>?
    /// Tracks live publisher updates independently from publisher recreation.
    private var updateLiveSettingsTask: Task<Void, Never>?
    /// Invalidates live-update tasks whose repository emissions arrive out of order.
    private var liveSettingsGeneration = 0
    /// Orders stats writes, final clear, and subsequent source subscriptions.
    private let statsForwarding: StatsForwardingLifecycle

    /// The active call façade, injected by the plugin coordinator.
    public weak var call: (any CallFacade)?

    /// Reactive source of publisher settings preferences (includes `senderStatsEnabled`).
    private let settingsRepository: PublisherSettingsRepository

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
        self.statsForwarding = StatsForwardingLifecycle(writer: statsWriter)
    }

    // MARK: - VonagePluginCallLifeCycle

    /// Called when the call starts and the Vonage session is connected.
    ///
    /// Sets up Combine subscriptions to bridge settings preferences with the call.
    ///
    /// - Parameter userInfo: Contextual info passed by the plugin coordinator (unused).
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        guard !isStarted else { return }
        isStarted = true
        lifecycleGeneration &+= 1
        let generation = lifecycleGeneration
        await teardownTask?.value
        guard isCurrentLifecycle(generation) else { return }
        await initObservers(generation: generation)
        guard isCurrentLifecycle(generation) else { return }
        call?.enableNetworkStats()
        let currentPreferences = await settingsRepository.getPreferences()
        guard isCurrentLifecycle(generation) else { return }
        if currentPreferences.senderStatsEnabled {
            call?.enableSubscriberExtraStats()
        } else {
            call?.disableSubscriberExtraStats()
        }
    }

    /// Called when the call ends and the Vonage session is disconnecting.
    ///
    /// Cancels subscriptions, waits for in-flight stats writes, then clears stats.
    /// A custom writer must complete its awaited write for teardown to finish.
    public func callDidEnd() async throws {
        isStarted = false
        lifecycleGeneration &+= 1
        let predecessor = teardownTask
        let teardown = Task {
            await predecessor?.value
            await cancelObservables()
        }
        teardownTask = teardown
        await teardown.value
    }

    // MARK: - Private

    private func isCurrentLifecycle(_ generation: UInt64) -> Bool {
        isStarted && lifecycleGeneration == generation
    }

    private func initObservers(generation: UInt64) async {
        // Observe the sender stats toggle and enable/disable network stats collection.
        settingsRepository.preferencesPublisher
            .map(\.senderStatsEnabled)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { @Sendable [weak self] isEnabled in
                MainActor.assumeIsolated {
                    guard let self, self.isCurrentLifecycle(generation) else { return }
                    if isEnabled {
                        self.call?.enableSubscriberExtraStats()
                    } else {
                        self.call?.disableSubscriberExtraStats()
                    }
                }
            }
            .store(in: &cancellables)

        // Observe settings that require recreating the publisher. Live-updatable
        // fields are intentionally ignored by the duplicate comparison.
        settingsRepository.preferencesPublisher
            .map { @Sendable preferences in preferences.toPublisherAdvancedSettings() }
            .removeDuplicates(by: { @Sendable previous, current in previous.hasEqualRepublishSettings(to: current) })
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { @Sendable [weak self] settings in
                MainActor.assumeIsolated {
                    guard let self, self.isCurrentLifecycle(generation), let call = self.call else { return }
                    // Cancel any in-flight republish cycle before starting a new one so
                    // the latest settings always win and the overlay can't get stuck.
                    let predecessor = self.applySettingsTask
                    predecessor?.cancel()
                    self.applySettingsTask = Task { [weak call] in
                        // An active SDK republish must finish its restore phase before the next
                        // cycle begins; cancellation can only skip a cycle that has not started.
                        await predecessor?.value
                        guard !Task.isCancelled else { return }
                        try? await call?.applyPublisherAdvancedSettings(settings)
                    }
                }
            }
            .store(in: &cancellables)

        // Apply bitrate and degradation changes directly to the active publisher.
        settingsRepository.preferencesPublisher
            .map { @Sendable preferences in preferences.toPublisherAdvancedSettings() }
            .removeDuplicates(by: { @Sendable previous, current in previous.hasEqualLiveSettings(to: current) })
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { @Sendable [weak self] settings in
                MainActor.assumeIsolated {
                    guard let self, self.isCurrentLifecycle(generation), let call = self.call else { return }
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
            }
            .store(in: &cancellables)

        // Source changes are queued behind any previous forwarding/clear operation.
        if let publisher = call?.networkStatsPublisher {
            let start = await statsForwarding.start(publisher)
            await start.value
        }
    }

    private func cancelObservables() async {
        let apply = applySettingsTask
        apply?.cancel()
        applySettingsTask = nil
        liveSettingsGeneration += 1
        let liveUpdate = updateLiveSettingsTask
        liveUpdate?.cancel()
        updateLiveSettingsTask = nil
        cancellables.removeAll()
        await apply?.value
        await liveUpdate?.value
        let stop = await statsForwarding.stop()
        await stop.value
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
