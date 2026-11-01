//
//  Created by Vonage on 1/11/26.
//

import CoreImage
import CoreVideo
import Foundation

/// Placement of the front-camera window on the rear-camera frame.
struct DualCaptureFrameLayout: Equatable {
    var insetWidthFraction: CGFloat = 0.28
    var marginFraction: CGFloat = 0.04
    /// Fraction of the frame height kept clear above the front-camera window.
    /// A one-to-one call draws the navigation bar over the top of a full-screen picture.
    var topClearanceFraction: CGFloat = 0.12
    var borderWidth: CGFloat = 4

    static let standard = DualCaptureFrameLayout()
}

/// Draws the rear camera full-frame and the front camera into a corner window.
enum DualCaptureCompositor {
    static func render(
        rear: CVPixelBuffer,
        front: CVPixelBuffer?,
        into output: CVPixelBuffer,
        showsFront: Bool,
        layout: DualCaptureFrameLayout = .standard,
        context: CIContext
    ) {
        let outputWidth = CGFloat(CVPixelBufferGetWidth(output))
        let outputHeight = CGFloat(CVPixelBufferGetHeight(output))
        let bounds = CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight)
        let background = aspectFill(CIImage(cvPixelBuffer: rear), in: bounds)
        let image = compositedFront(
            front,
            over: background,
            bounds: bounds,
            showsFront: showsFront,
            layout: layout
        )
        context.render(
            image,
            to: output,
            bounds: bounds,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
    }

    /// Longest edge capped near `maxEdge`, with both edges rounded up to a multiple of 16.
    static func outputSize(width: Int, height: Int, maxEdge: Int = 1280) -> (width: Int, height: Int) {
        let longest = max(width, height)
        let scale = longest > maxEdge ? Double(maxEdge) / Double(longest) : 1
        let fittedWidth = align((Double(width) * scale).rounded())
        let fittedHeight = align((Double(height) * scale).rounded())
        return (max(fittedWidth, 16), max(fittedHeight, 16))
    }

    private static func align(_ value: Double) -> Int {
        let rounded = Int(value)
        let remainder = rounded % 16
        return remainder == 0 ? rounded : rounded + (16 - remainder)
    }

    private static func compositedFront(
        _ front: CVPixelBuffer?,
        over background: CIImage,
        bounds: CGRect,
        showsFront: Bool,
        layout: DualCaptureFrameLayout
    ) -> CIImage {
        guard showsFront, let front else { return background }
        let inset = windowRect(in: bounds, layout: layout)
        let border = inset.insetBy(dx: -layout.borderWidth, dy: -layout.borderWidth)
        let frame = CIImage(color: CIColor(red: 1, green: 1, blue: 1)).cropped(to: border)
        let window = aspectFill(CIImage(cvPixelBuffer: front), in: inset)
        return window.composited(over: frame).composited(over: background)
    }

    /// Top-right window in Core Image coordinates, where y grows upward.
    static func windowRect(in bounds: CGRect, layout: DualCaptureFrameLayout = .standard) -> CGRect {
        let shortSide = min(bounds.width, bounds.height)
        let insetSide = shortSide * layout.insetWidthFraction
        let sideMargin = shortSide * layout.marginFraction
        let topClearance = bounds.height * layout.topClearanceFraction
        let lowestTop = max(sideMargin, bounds.height - insetSide - sideMargin)
        let topInset = min(max(topClearance, sideMargin), lowestTop)
        return CGRect(
            x: bounds.width - sideMargin - insetSide,
            y: bounds.height - topInset - insetSide,
            width: insetSide,
            height: insetSide
        )
    }

    private static func aspectFill(_ image: CIImage, in rect: CGRect) -> CIImage {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return image }
        let scale = max(rect.width / extent.width, rect.height / extent.height)
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let scaledExtent = scaled.extent
        let translated = scaled.transformed(
            by: CGAffineTransform(
                translationX: rect.midX - scaledExtent.midX,
                y: rect.midY - scaledExtent.midY
            )
        )
        return translated.cropped(to: rect)
    }
}
