//
//  Created by Vonage on 04/03/2026.
//

import Combine
import OpenTok
import VERADomain

@MainActor
public final class NullStatsCollector: NSObject, StatsCollector {

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    public func reset() {}

    public func requestRtcStats(from subscriber: OTSubscriberKit) {}

    public func requestRtcStats(from publisher: OTPublisherKit) {}

    public func removeSubscriber(connectionId: String) {}

    // MARK: - OTPublisherKitNetworkStatsDelegate

    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {}

    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {}

    // MARK: - OTSubscriberKitNetworkStatsDelegate

    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {}

    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {}

    // MARK: - OTPublisherKitRtcStatsReportDelegate

    nonisolated public func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {}

    // MARK: - OTSubscriberKitRtcStatsReportDelegate

    nonisolated public func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {}

    // MARK: - Publisher Media Link Stats

    nonisolated public func publisher(
        _ publisher: OTPublisherKit,
        mediaLinkStatsUpdated mediaLinkStats: [OTPublisherKitMediaLinkStats]
    ) {}

    // MARK: - Subscriber Media Link Stats

    nonisolated public func subscriber(
        _ subscriber: OTSubscriberKit,
        mediaLinkStatsUpdated mediaLinkStats: OTSubscriberKitMediaLinkStats
    ) {}
}
