//
//  Created by Vonage on 11/5/26.
//

import Foundation
import OpenTok

/// Namespace + key for the passthrough frame counter transformer.
public enum FrameCounter {
    public static let key = "FrameCounter"
}

/// Passthrough `OTCustomVideoTransformer` that does no image processing — it only
/// reports frame arrival and resolution to ``TransformPerformanceTracker``.
///
/// Used on the Vonage Media Library blur path so the performance HUD can show FPS
/// and resolution numbers. Our Apple Vision transformer already records its own
/// timing, so the counter is only attached on the Vonage path to avoid double
/// counting.
public final class FrameCounterTransformer: NSObject, OTCustomVideoTransformer {

    private var hasPushedResolution = false

    public override init() {
        super.init()
    }

    public func transform(_ videoFrame: OTVideoFrame) {
        TransformPerformanceTracker.shared.recordFrame()

        if !hasPushedResolution, let format = videoFrame.format {
            hasPushedResolution = true
            TransformPerformanceTracker.shared.setResolution(
                width: Int(format.imageWidth),
                height: Int(format.imageHeight)
            )
        }
    }
}
