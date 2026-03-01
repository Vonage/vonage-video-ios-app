import CoreMedia
import CoreVideo
import Foundation
import OpenTok

final class ScreenShareVideoCapturer: NSObject, OTVideoCapture {
    var videoContentHint: OTVideoContentHint = .detail
    var videoCaptureConsumer: OTVideoCaptureConsumer?

    private let captureQueue = DispatchQueue(label: "com.vonage.screenshare.capture")
    private var capturing = false

    // Initialize with a valid format to prevent empty bytesPerRow crash
    private var videoFrame: OTVideoFrame = {
        let format = OTVideoFormat()
        format.pixelFormat = .ARGB
        format.imageWidth = 1
        format.imageHeight = 1
        format.bytesPerRow = NSMutableArray(array: [4]) // Always non-empty
        return OTVideoFrame(format: format)
    }()

    func initCapture() {}
    func releaseCapture() {}

    func start() -> Int32 {
        captureQueue.sync { capturing = true }
        return 0
    }

    func stop() -> Int32 {
        captureQueue.sync { capturing = false }
        return 0
    }

    func isCaptureStarted() -> Bool {
        captureQueue.sync { capturing }
    }

    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        // Copy current valid format to prevent empty array access
        videoFormat.pixelFormat = videoFrame.format?.pixelFormat ?? .ARGB
        videoFormat.imageWidth = videoFrame.format?.imageWidth ?? 1
        videoFormat.imageHeight = videoFrame.format?.imageHeight ?? 1
        if let bytesPerRow = videoFrame.format?.bytesPerRow, bytesPerRow.count > 0 {
            videoFormat.bytesPerRow = bytesPerRow.mutableCopy() as! NSMutableArray
        } else {
            videoFormat.bytesPerRow = NSMutableArray(array: [4])
        }
        return 0
    }

    func consumeVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        captureQueue.sync {
            guard capturing,
                  let consumer = videoCaptureConsumer,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }

            let width = UInt32(CVPixelBufferGetWidth(pixelBuffer))
            let height = UInt32(CVPixelBufferGetHeight(pixelBuffer))
            let stride = CVPixelBufferGetBytesPerRow(pixelBuffer)

            // Update format if size changed, ensuring bytesPerRow stays populated
            if let format = videoFrame.format,
               (format.imageWidth != width || format.imageHeight != height || format.bytesPerRow.count == 0) {
                format.imageWidth = width
                format.imageHeight = height
                format.bytesPerRow.removeAllObjects()
                format.bytesPerRow.add(stride)
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

            videoFrame.timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoFrame.orientation = .up

            var plane0 = baseAddress.assumingMemoryBound(to: UInt8.self)
            videoFrame.setPlanesWithPointers(&plane0, numPlanes: 1)

            consumer.consumeFrame(videoFrame)
        }
    }
}
