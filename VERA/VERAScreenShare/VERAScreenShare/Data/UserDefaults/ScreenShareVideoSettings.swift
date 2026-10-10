import Foundation

/// Video policy transferred from the app to the ReplayKit extension at broadcast start.
public struct ScreenShareVideoSettings: Codable, Equatable {
    public var contentHint: Int
    public var preferredCodecs: [Int]?
    public var frameRate: Int?
    public var maxWidth: Int?
    public var maxHeight: Int?
    public var bitratePreset: Int?
    public var maxVideoBitrate: Int32
    public var scalableScreenshare: Bool

    public init(
        contentHint: Int = 2, preferredCodecs: [Int]? = nil, frameRate: Int? = nil,
        maxSize: (width: Int, height: Int)? = nil, bitratePreset: Int? = nil,
        maxVideoBitrate: Int32 = 500_000, scalableScreenshare: Bool = false
    ) {
        self.contentHint = contentHint
        self.preferredCodecs = preferredCodecs
        self.frameRate = frameRate
        self.maxWidth = maxSize?.width
        self.maxHeight = maxSize?.height
        self.bitratePreset = bitratePreset
        self.maxVideoBitrate = maxVideoBitrate
        self.scalableScreenshare = scalableScreenshare
    }

    /// Keeps the screen aspect ratio and aligns buffers to the codec's 16-pixel blocks.
    /// Default preserves the existing 1280-pixel longest-edge memory limit.
    public func outputDimensions(width: Int, height: Int) -> (width: Int, height: Int) {
        guard width > 0, height > 0 else { return (16, 16) }
        var boundWidth = Double(min(max(maxWidth ?? 1280, 16), 1920))
        var boundHeight = Double(min(max(maxHeight ?? 1280, 16), 1920))
        if width < height && boundWidth > boundHeight { swap(&boundWidth, &boundHeight) }
        let scale = min(1, boundWidth / Double(width), boundHeight / Double(height))
        return (
            max(16, Int(Double(width) * scale) / 16 * 16),
            max(16, Int(Double(height) * scale) / 16 * 16)
        )
    }

    public var minimumFrameInterval: Double {
        guard let frameRate, frameRate > 0 else { return 0 }
        return 1 / Double(min(frameRate, 30))
    }
}
