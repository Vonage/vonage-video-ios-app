//
//  Created by Vonage on 21/6/26.
//

import AVFoundation
import Foundation
import OSLog
import OpenTok
import UIKit

/// UI layers and avatar drawing are main-actor owned; borrowed SDK frames are
/// converted synchronously on their delivery thread without retaining frame planes.
final class PictureInPictureVideoRenderer: UIView, OTVideoRender {
    private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")
    let inlineDisplayLayer: AVSampleBufferDisplayLayer
    private nonisolated let frames: FrameState

    var pipBufferDisplayLayer: AVSampleBufferDisplayLayer? {
        didSet { frames.setPiPRenderer(pipBufferDisplayLayer?.sampleBufferRenderer) }
    }

    var renderedFrameCount: Int { frames.frameCount }
    var isMirrored: Bool {
        get { frames.isMirrored }
        set { frames.setMirrored(newValue) }
    }
    var isPlaceholderActive: Bool { frames.isPlaceholderActive }
    private static let placeholderSize = CGSize(width: 640, height: 360)
    private var placeholderTimer: DispatchSourceTimer?
    private var placeholderName: String?

    override init(frame: CGRect) {
        let displayLayer = AVSampleBufferDisplayLayer()
        displayLayer.videoGravity = .resizeAspect
        inlineDisplayLayer = displayLayer
        frames = FrameState(inlineRenderer: displayLayer.sampleBufferRenderer)
        super.init(frame: frame)
        layer.addSublayer(displayLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        inlineDisplayLayer.frame = bounds
    }

    func startPlaceholder(name: String) {
        if isPlaceholderActive, placeholderName == name { return }
        Self.logger.debug("renderer.startPlaceholder")
        placeholderName = name
        frames.setPlaceholder(makePlaceholderPixelBuffer(name: name, size: Self.placeholderSize), active: true)
        placeholderTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            // The timer is explicitly registered on DispatchQueue.main.
            MainActor.assumeIsolated { self?.frames.enqueuePlaceholder() }
        }
        placeholderTimer = timer
        timer.resume()
    }

    func updatePlaceholderName(_ name: String) {
        guard isPlaceholderActive, placeholderName != name else { return }
        placeholderName = name
        frames.setPlaceholder(makePlaceholderPixelBuffer(name: name, size: Self.placeholderSize), active: true)
    }

    func stopPlaceholder() {
        guard isPlaceholderActive else { return }
        Self.logger.debug("renderer.stopPlaceholder")
        frames.setPlaceholder(nil, active: false)
        placeholderName = nil
        placeholderTimer?.cancel()
        placeholderTimer = nil
    }

    nonisolated func renderVideoFrame(_ frame: OTVideoFrame) {
        frames.render(frame)
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

    /// Duplicates the palette of `String.getParticipantColor()` (VERACore/VERACommonUI): those
    /// extensions are internal to their modules and return SwiftUI `Color`, so they cannot be used
    /// here. If the app palette changes, this must change with it.
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

    /// Duplicates `String.getInitials()` (VERACommonUI, not a dependency of this module) so the
    /// PiP avatar shows the same initials as the meeting room. Keep the logic in sync.
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

    /// The unchecked boundary contains only synchronized conversion state and AVFoundation's
    /// background-safe sample-buffer renderers. UI layers and borrowed OTVideoFrame values never
    /// escape into asynchronous work. Every mutable field is protected by lock, including reads.
    /// https://developer.apple.com/documentation/avfoundation/avsamplebufferdisplaylayer/samplebufferrenderer
    private final class FrameState: @unchecked Sendable {
        private let lock = NSLock()
        private let inlineRenderer: AVSampleBufferVideoRenderer
        private var pipRenderer: AVSampleBufferVideoRenderer?
        private let accelerator: YUVToARGBAccelerator
        private var mirrored = false
        private var placeholderActive = false
        private var placeholder: CVPixelBuffer?
        private var count = 0
        private var pixelBufferPool: CVPixelBufferPool?
        private var poolWidth = 0
        private var poolHeight = 0

        @MainActor init(inlineRenderer: AVSampleBufferVideoRenderer) {
            accelerator = YUVToARGBAccelerator()
            self.inlineRenderer = inlineRenderer
        }

        private func withLock<T>(_ body: () -> T) -> T {
            lock.lock()
            defer { lock.unlock() }
            return body()
        }

        var frameCount: Int { withLock { count } }
        var isMirrored: Bool { withLock { mirrored } }
        var isPlaceholderActive: Bool { withLock { placeholderActive } }

        func setPiPRenderer(_ renderer: AVSampleBufferVideoRenderer?) {
            withLock { pipRenderer = renderer }
        }

        func setMirrored(_ value: Bool) { withLock { mirrored = value } }

        func setPlaceholder(_ buffer: CVPixelBuffer?, active: Bool) {
            withLock {
                placeholder = buffer
                placeholderActive = active
            }
        }

        func enqueuePlaceholder() {
            withLock {
                guard placeholderActive, let placeholder,
                    let sample = createSampleBuffer(from: placeholder)
                else { return }
                display(sample)
            }
        }

        func render(_ frame: OTVideoFrame) {
            guard let format = frame.format, format.pixelFormat == .I420 else { return }
            withLock {
                // Placeholder changes, conversion and enqueue are serialized, so trailing
                // camera frames cannot replace the avatar after camera-off.
                guard !placeholderActive,
                    let sample = createSampleBuffer(
                        from: frame, width: Int(format.imageWidth), height: Int(format.imageHeight))
                else { return }
                display(sample)
            }
        }

        private func display(_ sample: CMSampleBuffer) {
            count += 1
            enqueue(sample, to: inlineRenderer)
            if let pipRenderer { enqueue(sample, to: pipRenderer) }
        }

        private func enqueue(_ sample: CMSampleBuffer, to renderer: AVSampleBufferVideoRenderer) {
            if renderer.status == .failed || renderer.requiresFlushToResumeDecoding {
                renderer.flush()
            }
            renderer.enqueue(sample)
        }

        private func createSampleBuffer(from frame: OTVideoFrame, width: Int, height: Int) -> CMSampleBuffer? {
            guard let pixelBuffer = dequeuePixelBuffer(width: width, height: height) else { return nil }
            guard accelerator.convertFrameVImageYUV(frame, to: pixelBuffer, mirrored: mirrored) == 0 else { return nil }
            return createSampleBuffer(from: pixelBuffer)
        }

        /// Returns a BGRA pixel buffer from a size-matched pool, (re)creating the pool only when the
        /// frame dimensions change. Called under `frameLock`, so the pool state needs no extra locking.
        private func dequeuePixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
            if pixelBufferPool == nil || width != poolWidth || height != poolHeight {
                let attributes: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:],
                ]
                var pool: CVPixelBufferPool?
                guard
                    CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pool)
                        == kCVReturnSuccess
                else {
                    return nil
                }
                pixelBufferPool = pool
                poolWidth = width
                poolHeight = height
            }

            guard let pixelBufferPool else { return nil }
            var pixelBuffer: CVPixelBuffer?
            guard
                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
                    == kCVReturnSuccess
            else {
                return nil
            }
            return pixelBuffer
        }

        private func createSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

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

    }
}
