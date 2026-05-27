//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Statistics for a single simulcast or SVC video layer published by the local user.
///
/// Populated from `OTPublisherKitVideoLayerStats` via the SDK's
/// `networkStatsDelegate` callback.
public struct VideoLayerStats: Equatable {
    /// Encoded frame width in pixels.
    public let width: Int32
    /// Encoded frame height in pixels.
    public let height: Int32
    /// Encoded frames per second for this layer.
    public let encodedFrameRate: Double
    /// Layer bitrate in bits per second (excluding RTP overhead).
    public let bitrate: Int64
    /// Layer bitrate in bits per second (including RTP overhead).
    public let totalBitrate: Int64
    /// The codec used by this video layer (e.g. "VP8", "H264", "VP9").
    public let codec: String?
    /// SVC/scalability descriptor (e.g. "L3T3"), if applicable.
    public let scalabilityMode: String?
    /// Reason for quality limitation on this layer.
    public let qualityLimitationReason: QualityLimitationReason

    public init(
        width: Int32 = 0,
        height: Int32 = 0,
        encodedFrameRate: Double = 0,
        bitrate: Int64 = 0,
        totalBitrate: Int64 = 0,
        codec: String? = nil,
        scalabilityMode: String? = nil,
        qualityLimitationReason: QualityLimitationReason = .none
    ) {
        self.width = width
        self.height = height
        self.encodedFrameRate = encodedFrameRate
        self.bitrate = bitrate
        self.totalBitrate = totalBitrate
        self.codec = codec
        self.scalabilityMode = scalabilityMode
        self.qualityLimitationReason = qualityLimitationReason
    }
}
