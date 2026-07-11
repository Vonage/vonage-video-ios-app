//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import VERADomain

/// Shows a floating stats overlay when the user has enabled the overlay toggle.
///
/// Observes ``PublisherSettingsRepository/preferencesPublisher`` to toggle visibility,
/// and ``StatsDataSource/statsPublisher`` to display real-time network metrics.
public final class StatsOverlayViewModel: ObservableObject {

    // MARK: - Published state

    /// Controls whether the stats overlay is currently visible.
    @Published public var isActive: Bool = false

    /// The formatted text to display in the stats overlay.
    /// Contains real-time network statistics formatted for display.
    @Published public var statsText: String = ""

    // MARK: - Properties

    /// Repository providing settings preferences including the overlay toggle.
    private let settingsRepository: PublisherSettingsRepository

    /// Data source providing real-time network statistics.
    private let statsDataSource: StatsDataSource

    /// Minimum time interval between stats UI updates in seconds.
    /// - `0`: No throttling (immediate updates)
    /// - `> 0`: Updates limited to once per interval
    private let statsUpdateInterval: TimeInterval

    /// Set of Combine subscriptions managed by this view model.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// Creates a new stats overlay view model.
    ///
    /// - Parameters:
    ///   - settingsRepository: Used to observe `statsOverlayEnabled`.
    ///   - statsDataSource: Provides real-time network stats.
    ///   - statsUpdateInterval: Minimum seconds between UI updates. Defaults to `0` (no throttling).
    ///                          Use values like `2.0` to make rapidly changing stats readable.
    public init(
        settingsRepository: PublisherSettingsRepository,
        statsDataSource: StatsDataSource,
        statsUpdateInterval: TimeInterval = 0
    ) {
        self.settingsRepository = settingsRepository
        self.statsDataSource = statsDataSource
        self.statsUpdateInterval = statsUpdateInterval
    }

    /// Sets up the observers for settings and stats changes.
    /// Should be called when the view appears.
    public func setup() {
        observeSettings()
        observeStats()
    }

    /// Removes all observers and cleans up subscriptions.
    /// Should be called when the view disappears.
    public func removeObservers() {
        cancellables.removeAll()
    }

    // MARK: - Private

    /// Observes the settings repository for changes to the overlay visibility toggle.
    private func observeSettings() {
        settingsRepository.preferencesPublisher
            .map(\.statsOverlayEnabled)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                guard let self else { return }

                self.isActive = isEnabled

                if !isEnabled {
                    self.statsText = ""
                }
            }
            .store(in: &cancellables)
    }

    /// Observes the stats data source for new network statistics.
    private func observeStats() {
        let publisher = statsDataSource.statsPublisher
            .receive(on: DispatchQueue.main)

        let throttledPublisher: AnyPublisher<NetworkMediaStats, Never>
        if statsUpdateInterval > 0 {
            throttledPublisher =
                publisher
                .throttle(for: .seconds(statsUpdateInterval), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        } else {
            throttledPublisher = publisher.eraseToAnyPublisher()
        }

        throttledPublisher
            .sink { [weak self] stats in
                guard let self, self.isActive else { return }

                self.buildStatsText(stats)
            }
            .store(in: &cancellables)
    }

    /// Builds the stats text from the latest statistics snapshot.
    ///
    /// - Parameter stats: The network media statistics to format.
    private func buildStatsText(_ stats: NetworkMediaStats) {
        Task { @MainActor in
            let maxAudioBitrate = await settingsRepository.getPreferences().audioBitratePreference.customValue
            self.statsText = await formatStats(stats, maxAudioBitrate: maxAudioBitrate)
        }
    }

    /// Formats network statistics into a human-readable multi-line string.
    ///
    /// - Parameters:
    ///   - stats: The network media statistics.
    ///   - maxAudioBitrate: The configured maximum audio bitrate, or `nil` for SDK default.
    /// - Returns: A formatted string with emoji icons and localized labels.
    private func formatStats(_ stats: NetworkMediaStats, maxAudioBitrate: Int32? = nil) async -> String {
        var lines: [String] = []

        if let audioSend = stats.sentAudio {
            let codecLabel = audioSend.audioCodec.map { " (\($0))" } ?? ""
            lines.append("🔊 Audio Send".localized(args: codecLabel))
            lines.append(
                "Sent".localized(args: audioSend.packetsSent.description, audioSend.bytesSentFormmatted.description))
            lines.append("Lost".localized(args: audioSend.packetsLost.description))
        }

        if let videoSend = stats.sentVideo {
            let codecLabel = videoSend.videoCodec.map { " (\($0))" } ?? ""
            lines.append("📹 Video Send".localized(args: codecLabel))
            lines.append("Sent".localized(args: videoSend.packetsSent.description, videoSend.bytesSentFormmatted))
            lines.append("Lost".localized(args: videoSend.packetsLost.description))
        }

        let audioRecvStats = stats.subscriberStats.compactMap(\.receivedAudio)
        if !audioRecvStats.isEmpty {
            let totalPacketsReceived = audioRecvStats.reduce(0) { $0 + $1.packetsReceived }
            let totalPacketsLost = audioRecvStats.reduce(0) { $0 + $1.packetsLost }
            let totalBytesReceived = audioRecvStats.reduce(0) { $0 + $1.bytesReceived }
            lines.append("🔈 Audio Recv".localized)
            lines.append(
                "Pkts".localized(args: totalPacketsReceived.description, totalPacketsLost.description))
            lines.append("Bytes".localized(args: SettingsFormatter.formatBytes(totalBytesReceived)))
            let maxBitrate = maxAudioBitrate.map { SettingsFormatter.formatBandwidth($0) ?? "" } ?? "Default".localized
            lines.append("Max Bitrate".localized(args: maxBitrate))
        }

        let videoRecvStats = stats.subscriberStats.compactMap(\.receivedVideo)
        if !videoRecvStats.isEmpty {
            let totalPacketsReceived = videoRecvStats.reduce(0) { $0 + $1.packetsReceived }
            let totalPacketsLost = videoRecvStats.reduce(0) { $0 + $1.packetsLost }
            let totalBytesReceived = videoRecvStats.reduce(0) { $0 + $1.bytesReceived }
            lines.append("📺 Video Recv".localized)
            lines.append(
                "Recv".localized(
                    args: totalPacketsReceived.description, SettingsFormatter.formatBytes(Int64(totalBytesReceived))))
            lines.append("Lost".localized(args: totalPacketsLost.description))
        }

        return lines.isEmpty ? "Waiting for stats…".localized : lines.joined(separator: "\n")
    }
}
