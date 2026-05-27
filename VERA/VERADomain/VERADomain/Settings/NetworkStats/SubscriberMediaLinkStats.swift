//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Transport-level statistics for a subscriber's connections, including
/// visibility into the remote publisher's network performance.
///
/// Populated from `OTSubscriberKitMediaLinkStats` via the SDK's
/// `OTSubscriberKitMediaLinkStatsDelegate` callback.
public struct SubscriberMediaLinkStats: Equatable {
    /// Transport statistics for this subscriber's downlink connection.
    public let transport: TransportStats
    /// Transport statistics for the remote publisher's uplink connection.
    /// Available only when the publisher has enabled sender-side statistics.
    public let remotePublisherTransport: TransportStats?
    /// Indicates the source of network degradation.
    public let networkDegradationSource: NetworkDegradationSource

    public init(
        transport: TransportStats = TransportStats(),
        remotePublisherTransport: TransportStats? = nil,
        networkDegradationSource: NetworkDegradationSource = .unknown
    ) {
        self.transport = transport
        self.remotePublisherTransport = remotePublisherTransport
        self.networkDegradationSource = networkDegradationSource
    }
}
