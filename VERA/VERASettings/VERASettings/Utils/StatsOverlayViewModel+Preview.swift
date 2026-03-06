//
//  Created by Vonage on 4/3/26.
//

#if DEBUG
    @preconcurrency import Combine
    import VERADomain
    import Foundation

    // MARK: - Mock Stats Data Source

    final class PreviewStatsDataSource: StatsDataSource {

        private nonisolated let subject = CurrentValueSubject<NetworkMediaStats, Never>(.mock)

        nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
            subject.eraseToAnyPublisher()
        }

        func updateStats(_ stats: NetworkMediaStats) async {
            subject.send(stats)
        }

        func clearStats() async {
            subject.send(.empty)
        }
    }

    // MARK: - Mock Data

    extension NetworkMediaStats {
        static var mock: NetworkMediaStats {
            NetworkMediaStats(
                sentAudio: AudioSendStats(
                    packetsSent: 1234,
                    packetsLost: 5,
                    bytesSent: 512_000,
                    timestamp: Date().timeIntervalSince1970,
                    audioCodec: "opus"
                ),
                sentVideo: VideoSendStats(
                    packetsSent: 8765,
                    packetsLost: 23,
                    bytesSent: 5_242_880,
                    timestamp: Date().timeIntervalSince1970,
                    videoCodec: "VP8"
                ),
                receivedAudio: AudioReceiveStats(
                    packetsReceived: 4321,
                    packetsLost: 12,
                    bytesReceived: 768_000,
                    timestamp: Date().timeIntervalSince1970,
                    estimatedBandwidth: 512_000
                ),
                receivedVideo: VideoReceiveStats(
                    packetsReceived: 9876,
                    packetsLost: 45,
                    bytesReceived: 6_291_456,
                    timestamp: Date().timeIntervalSince1970
                )
            )
        }
    }

    // MARK: - Preview Instances

    extension StatsOverlayViewModel {

        static var previewActive: StatsOverlayViewModel {
            let repo = PreviewSettingsRepository()
            var prefs = PublisherSettingsPreferences.default
            prefs.senderStatsEnabled = true
            repo.saveNoAsync(prefs)

            let vm = StatsOverlayViewModel(
                settingsRepository: repo,
                statsDataSource: PreviewStatsDataSource()
            )
            vm.isActive = true
            vm.setup()

            return vm
        }

        static var previewInactive: StatsOverlayViewModel {
            StatsOverlayViewModel(
                settingsRepository: PreviewSettingsRepository(),
                statsDataSource: PreviewStatsDataSource()
            )
        }
    }
#endif
