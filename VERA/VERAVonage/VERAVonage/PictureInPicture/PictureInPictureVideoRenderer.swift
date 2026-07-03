//
//  Created by Vonage on 21/6/26.
//

import AVFoundation
import Foundation
import OSLog
import OpenTok
import UIKit

/// Custom `OTVideoRender` that displays inline video and feeds frames into PiP.
final class PictureInPictureVideoRenderer: UIView, OTVideoRender {
    private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")

    lazy var inlineDisplayLayer: AVSampleBufferDisplayLayer = {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        return layer
    }()
    var pipBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private(set) var renderedFrameCount = 0

    /// Invoked once when this view is mounted in a window with a usable size, so it can serve as the
    /// `activeVideoCallSourceView` for PiP when the renderer itself is embedded in the participant
    /// tile (the permanently-attached local publisher renderer). Reset via
    /// ``resetSourceViewReadyNotification()`` when the PiP controller needs reconfiguring.
    var onSourceViewReady: ((UIView, CGRect) -> Void)?
    private var didNotifySourceViewReady = false

    /// Horizontally mirrors live video frames. Set for the local front camera so the self-view
    /// matches the mirrored preview used elsewhere (e.g. the waiting room); remote video and the
    /// back camera stay un-mirrored. Applied to the pixels, so the placeholder avatar is unaffected.
    var isMirrored = false

    private let frameLock = NSLock()
    private let accelerator = YUVToARGBAccelerator()

    // MARK: - Placeholder (camera-off avatar)

    /// Size of the generated avatar placeholder. 16:9 matches `Participant.aspectRatio`'s
    /// camera-off fallback so the tile lays out identically to a video tile.
    private static let placeholderSize = CGSize(width: 640, height: 360)
    private var placeholderTimer: DispatchSourceTimer?
    private var placeholderName: String?
    private var placeholderPixelBuffer: CVPixelBuffer?
    private(set) var isPlaceholderActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        layer.addSublayer(inlineDisplayLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        inlineDisplayLayer.frame = bounds
        notifySourceViewReadyIfEligible()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        notifySourceViewReadyIfEligible()
    }

    /// Fires ``onSourceViewReady`` when this view is in a window with a usable size. Safe to call
    /// repeatedly; delivers at most once until ``resetSourceViewReadyNotification()``.
    func notifySourceViewReadyIfEligible() {
        guard !didNotifySourceViewReady,
            onSourceViewReady != nil,
            window != nil,
            bounds.width > 1,
            bounds.height > 1
        else { return }

        didNotifySourceViewReady = true
        Self.logger.debug("renderer.sourceViewReady \(String(describing: self.bounds.size), privacy: .public)")
        onSourceViewReady?(self, bounds)
    }

    /// Allows ``onSourceViewReady`` to fire again after the PiP controller was torn down.
    func resetSourceViewReadyNotification() {
        didNotifySourceViewReady = false
    }

    /// Resets PiP buffer wiring after camera toggles or controller teardown.
    func prepareForPipRefresh() {
        flush(layer: inlineDisplayLayer)
        if let pipBufferDisplayLayer {
            flush(layer: pipBufferDisplayLayer)
        }
        pipBufferDisplayLayer = nil
    }

    // MARK: - Placeholder

    /// Starts feeding an avatar placeholder (initials on the participant's color) into the inline
    /// and PiP layers. Used when the target participant has their camera off so PiP stays available.
    func startPlaceholder(name: String) {
        if isPlaceholderActive, placeholderName == name { return }

        isPlaceholderActive = true
        placeholderName = name
        placeholderPixelBuffer = makePlaceholderPixelBuffer(name: name, size: Self.placeholderSize)

        placeholderTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            self?.enqueuePlaceholderFrame()
        }
        placeholderTimer = timer
        timer.resume()
    }

    /// Refreshes the placeholder image when the participant's name changes.
    func updatePlaceholderName(_ name: String) {
        guard isPlaceholderActive, placeholderName != name else { return }
        placeholderName = name
        placeholderPixelBuffer = makePlaceholderPixelBuffer(name: name, size: Self.placeholderSize)
    }

    func stopPlaceholder() {
        guard isPlaceholderActive else { return }
        isPlaceholderActive = false
        placeholderName = nil
        placeholderPixelBuffer = nil
        placeholderTimer?.cancel()
        placeholderTimer = nil
    }

    private func enqueuePlaceholderFrame() {
        frameLock.lock()
        defer { frameLock.unlock() }

        guard isPlaceholderActive,
            let placeholderPixelBuffer,
            let sampleBuffer = createSampleBuffer(from: placeholderPixelBuffer)
        else { return }

        renderedFrameCount += 1
        enqueue(sampleBuffer, to: inlineDisplayLayer)
        if let pipBufferDisplayLayer {
            enqueue(sampleBuffer, to: pipBufferDisplayLayer)
        }
    }

    func renderVideoFrame(_ frame: OTVideoFrame) {
        guard let format = frame.format, format.pixelFormat == .I420 else { return }

        // While the avatar placeholder is active the manager is the source of truth for the
        // camera state. Drop incoming frames (including trailing frames delivered right after a
        // camera-off) so they can't cancel the placeholder or freeze PiP on a stale frame. The
        // manager explicitly stops the placeholder when the camera is re-enabled.
        if isPlaceholderActive { return }

        frameLock.lock()
        defer { frameLock.unlock() }

        guard
            let sampleBuffer = createSampleBuffer(
                from: frame,
                width: Int(format.imageWidth),
                height: Int(format.imageHeight)
            )
        else { return }

        renderedFrameCount += 1
        // Sparse heartbeat (~every 4s at 30fps) to tell "frames stopped arriving" apart from
        // "frames arrive but don't display" when diagnosing frozen video.
        if renderedFrameCount == 1 || renderedFrameCount % 120 == 0 {
            let message =
                "renderer.frame #\(renderedFrameCount) "
                + "\(Int(format.imageWidth))x\(Int(format.imageHeight)) "
                + "pipLayer=\(pipBufferDisplayLayer != nil)"
            Self.logger.debug("\(message, privacy: .public)")
        }
        enqueue(sampleBuffer, to: inlineDisplayLayer)
        if let pipBufferDisplayLayer {
            enqueue(sampleBuffer, to: pipBufferDisplayLayer)
        }
    }

    private func enqueue(_ sampleBuffer: CMSampleBuffer, to layer: AVSampleBufferDisplayLayer) {
        // A failed layer silently drops every subsequent enqueue; only a flush revives it.
        // `requiresFlushToResumeDecoding` does not cover the `.failed` state.
        if layer.status == .failed || layer.requiresFlushToResumeDecoding {
            layer.flush()
        }
        layer.enqueue(sampleBuffer)
    }

    private func flush(layer: AVSampleBufferDisplayLayer) {
        if layer.requiresFlushToResumeDecoding {
            layer.flush()
        }
    }

    private func createSampleBuffer(from frame: OTVideoFrame, width: Int, height: Int) -> CMSampleBuffer? {
        let pixelAttributes: NSDictionary = [kCVPixelBufferIOSurfacePropertiesKey as String: [:]]
        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            pixelAttributes as CFDictionary,
            &pixelBuffer
        )
        guard result == kCVReturnSuccess, let pixelBuffer else { return nil }

        _ = accelerator.convertFrameVImageYUV(frame, to: pixelBuffer, mirrored: isMirrored)
        return createSampleBuffer(from: pixelBuffer)
    }

    private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        var sampleBuffer: CMSampleBuffer?
        let now = CMTimeMakeWithSeconds(CACurrentMediaTime(), preferredTimescale: 1000)
        var timingInfo = CMSampleTimingInfo(
            duration: CMTimeMake(value: 1, timescale: 1000),
            presentationTimeStamp: now,
            decodeTimeStamp: now
        )

        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )

        guard let formatDescription else { return nil }

        let status = CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timingInfo,
            sampleBufferOut: &sampleBuffer
        )

        guard status == noErr else { return nil }
        return sampleBuffer
    }

    // MARK: - Placeholder drawing

    private func makePlaceholderPixelBuffer(name: String, size: CGSize) -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)
        let attributes: NSDictionary = [
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]

        var pixelBuffer: CVPixelBuffer?
        let result = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )
        guard result == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard
            let context = CGContext(
                data: CVPixelBufferGetBaseAddress(pixelBuffer),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
            )
        else { return nil }

        // Flip into UIKit's top-left coordinate space so text/ellipses draw upright.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)

        UIGraphicsPushContext(context)
        drawPlaceholder(name: name, size: size)
        UIGraphicsPopContext()

        return pixelBuffer
    }

    private func drawPlaceholder(name: String, size: CGSize) {
        UIColor(white: 0.13, alpha: 1).setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        let diameter = min(size.width, size.height) * 0.55
        let circleRect = CGRect(
            x: (size.width - diameter) / 2,
            y: (size.height - diameter) / 2,
            width: diameter,
            height: diameter
        )
        Self.participantColor(for: name).setFill()
        UIBezierPath(ovalIn: circleRect).fill()

        let initials = Self.initials(from: name)
        guard !initials.isEmpty else { return }

        let font = UIFont.systemFont(ofSize: diameter * 0.4, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white,
        ]
        let textSize = (initials as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: circleRect.midX - textSize.width / 2,
            y: circleRect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (initials as NSString).draw(in: textRect, withAttributes: attributes)
    }

    /// Mirrors `String.getParticipantColor()` so the PiP avatar matches the meeting room palette.
    private static func participantColor(for name: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1),
            UIColor(red: 0.38, green: 0.49, blue: 0.54, alpha: 1),
            UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1),
            UIColor(red: 0.40, green: 0.23, blue: 0.72, alpha: 1),
            UIColor(red: 0.25, green: 0.32, blue: 0.71, alpha: 1),
            UIColor(red: 0.13, green: 0.58, blue: 0.95, alpha: 1),
            UIColor(red: 1.00, green: 0.34, blue: 0.13, alpha: 1),
            UIColor(red: 0.00, green: 0.74, blue: 0.83, alpha: 1),
            UIColor(red: 1.00, green: 0.76, blue: 0.03, alpha: 1),
            UIColor(red: 0.30, green: 0.69, blue: 0.31, alpha: 1),
        ]
        let asciiSum = name.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        return colors[asciiSum % colors.count]
    }

    /// Mirrors `String.getInitials()` so the PiP avatar shows the same initials as the meeting room.
    private static func initials(from name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .filter { $0.isLetter || $0.isNumber }

        switch parts.count {
        case 0: return ""
        case 1: return String(parts[0]).uppercased()
        default: return "\(parts.first!)\(parts.last!)".uppercased()
        }
    }
}
