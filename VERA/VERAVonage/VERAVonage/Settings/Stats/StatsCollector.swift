//
//  Created by Vonage on 04/03/2026.
//

import Combine
import OpenTok
import VERADomain

public protocol StatsCollector: OTPublisherKitNetworkStatsDelegate,
    OTSubscriberKitNetworkStatsDelegate,
    OTPublisherKitRtcStatsReportDelegate,
    OTSubscriberKitRtcStatsReportDelegate
{
    var statsPublisher: AnyPublisher<NetworkMediaStats, Never> { get }

    func reset()
    func requestRtcStats(from subscriber: OTSubscriberKit)
    func requestRtcStats(from publisher: OTPublisherKit)
}
