//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Transport-level statistics for a publisher's uplink connection.
///
/// Populated from `OTPublisherKitMediaLinkStats` via the SDK's
/// `OTPublisherKitMediaLinkStatsDelegate` callback.
public struct PublisherMediaLinkStats: Equatable {
    /// Transport statistics for the publisher's uplink connection.
    public let transport: TransportStats

    public init(transport: TransportStats = TransportStats()) {
        self.transport = transport
    }
}
