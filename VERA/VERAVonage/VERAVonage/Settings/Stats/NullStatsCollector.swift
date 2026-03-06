//
//  Created by Vonage on 04/03/2026.
//

import Combine
import OpenTok
import VERADomain

public final class NullStatsCollector: NSObject, StatsCollector {

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    public func reset() {}

    public func requestRtcStats(from subscriber: OTSubscriberKit) {}

    public func requestRtcStats(from publisher: OTPublisherKit) {}

    // MARK: - OTPublisherKitNetworkStatsDelegate

    public func publisher(
        _ publisher: OTPublisherKit,
        videoNetworkStatsUpdated stats: [OTPublisherKitVideoNetworkStats]
    ) {}

    public func publisher(
        _ publisher: OTPublisherKit,
        audioNetworkStatsUpdated stats: [OTPublisherKitAudioNetworkStats]
    ) {}

    // MARK: - OTSubscriberKitNetworkStatsDelegate

    public func subscriber(
        _ subscriber: OTSubscriberKit,
        videoNetworkStatsUpdated stats: OTSubscriberKitVideoNetworkStats
    ) {}

    public func subscriber(
        _ subscriber: OTSubscriberKit,
        audioNetworkStatsUpdated stats: OTSubscriberKitAudioNetworkStats
    ) {}

    // MARK: - OTPublisherKitRtcStatsReportDelegate

    public func publisher(_ publisher: OTPublisherKit, rtcStatsReport stats: [OTPublisherRtcStats]) {}

    // MARK: - OTSubscriberKitRtcStatsReportDelegate

    public func subscriber(_ subscriber: OTSubscriberKit, rtcStatsReport jsonArrayString: String) {}
}
