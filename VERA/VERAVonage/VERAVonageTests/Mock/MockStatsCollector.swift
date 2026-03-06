//
//  Created by Vonage on 05/03/2026.
//

import VERAVonage
import VERADomain
import Foundation
import Combine
import OpenTok

public final class MockStatsCollector: NSObject, StatsCollector {

    private let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    public var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Tracking Properties

    public var requestRtcStatsFromPublisherCallCount = 0
    public var requestRtcStatsFromSubscriberCallCount = 0
    public var resetCallCount = 0
    public var publishersRequested: [OTPublisherKit] = []
    public var subscribersRequested: [OTSubscriberKit] = []

    public func reset() {
        resetCallCount += 1
    }

    public func requestRtcStats(from subscriber: OTSubscriberKit) {
        requestRtcStatsFromSubscriberCallCount += 1
        subscribersRequested.append(subscriber)
    }

    public func requestRtcStats(from publisher: OTPublisherKit) {
        requestRtcStatsFromPublisherCallCount += 1
        publishersRequested.append(publisher)
    }

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
