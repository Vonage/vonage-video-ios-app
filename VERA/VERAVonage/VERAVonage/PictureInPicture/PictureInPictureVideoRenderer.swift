//
//  Created by Vonage on 21/6/26.
//

import AVFoundation
import Foundation
import OpenTok
import UIKit

/// Custom `OTVideoRender` that displays inline video and feeds frames into PiP.
final class PictureInPictureVideoRenderer: UIView, OTVideoRender {
    let inlineDisplayLayer = AVSampleBufferDisplayLayer()
    var pipBufferDisplayLayer: AVSampleBufferDisplayLayer?
    private(set) var renderedFrameCount = 0

    private let frameLock = NSLock()
    private let accelerator = YUVToARGBAccelerator()

    override init(frame: CGRect) {
        super.init(frame: frame)
        inlineDisplayLayer.videoGravity = .resizeAspect
        layer.addSublayer(inlineDisplayLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        inlineDisplayLayer.frame = bounds
    }

    /// Resets PiP buffer wiring after camera toggles or controller teardown.
    func prepareForPipRefresh() {
        flush(layer: inlineDisplayLayer)
        if let pipBufferDisplayLayer {
            flush(layer: pipBufferDisplayLayer)
        }
        pipBufferDisplayLayer = nil
    }

    func renderVideoFrame(_ frame: OTVideoFrame) {
        guard let format = frame.format, format.pixelFormat == .I420 else { return }

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
        enqueue(sampleBuffer, to: inlineDisplayLayer)
        if let pipBufferDisplayLayer {
            enqueue(sampleBuffer, to: pipBufferDisplayLayer)
        }
    }

    private func enqueue(_ sampleBuffer: CMSampleBuffer, to layer: AVSampleBufferDisplayLayer) {
        if layer.requiresFlushToResumeDecoding {
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

        _ = accelerator.convertFrameVImageYUV(frame, to: pixelBuffer)
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
}
