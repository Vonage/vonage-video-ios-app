//
//  Created by Vonage on 19/11/26.
//

import CoreGraphics
import Foundation

/// Output size for a screen-share frame.
///
/// The size is the captured content's pixel size. Both edges are rounded up to a multiple
/// of 16 so the encoder receives an aligned frame. An empty size falls back to 1280x720.
public enum ScreenShareFrameSize {
    public static let alignment: CGFloat = 16

    public static func outputSize(inputWidth: Int, inputHeight: Int) -> (width: Int, height: Int) {
        guard inputWidth > 0, inputHeight > 0 else { return (1280, 720) }
        return (align(CGFloat(inputWidth)), align(CGFloat(inputHeight)))
    }

    /// Converts a picker content rect from points to the content's pixel size.
    public static func outputSize(contentRect: CGRect, pointPixelScale: CGFloat) -> (width: Int, height: Int) {
        let width = Int((contentRect.width * pointPixelScale).rounded())
        let height = Int((contentRect.height * pointPixelScale).rounded())
        return outputSize(inputWidth: width, inputHeight: height)
    }

    private static func align(_ value: CGFloat) -> Int {
        let remainder = value.truncatingRemainder(dividingBy: alignment)
        guard remainder != 0 else { return Int(value) }
        return Int(value + (alignment - remainder))
    }
}
