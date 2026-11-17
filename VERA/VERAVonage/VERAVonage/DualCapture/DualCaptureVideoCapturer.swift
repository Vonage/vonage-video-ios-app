//
//  Created by Vonage on 1/11/26.
//

import AVFoundation
import CoreImage
import CoreMedia
import CoreVideo
import Foundation
import OpenTok

enum DualCaptureSessionError: Error {
    case camerasUnavailable
    case cannotConfigure
    case overBudget
}

private enum DualCaptureCamera: Sendable {
    case rear
    case front
}

/// Publishes the rear camera full-frame with the front camera in a corner window.
///
/// Sendable is unchecked because AVFoundation and the Vonage consumer are not Sendable.
/// Three domains keep that promise:
/// - `controlLock` guards the consumer, the running flag, and closure. Nothing is called out
///   while it is held.
/// - The session queue alone owns the capture session, connections, and outputs.
/// - The video queue alone owns sample buffers, the output pixel buffer, and `CIContext`.
///   Sample buffers are never enqueued or sent to another queue. A busy render drops the new
///   frame. The SDK consumer runs only after `controlLock` is released.
final class DualCaptureVideoCapturer: NSObject, OTVideoCapture, @unchecked Sendable {
    private let controlLock = NSLock()
    private let frameLock = NSLock()
    private let conversionLock = NSLock()
    private let sessionQueue = DispatchQueue(label: "com.vonage.VERA.dualcapture.session")
    private let videoQueue = DispatchQueue(label: "com.vonage.VERA.dualcapture.video")
    private let orientationWatcher = DualCaptureOrientationWatcher()

    // Session-queue only.
    private var session: AVCaptureMultiCamSession?
    private var rearOutput: AVCaptureVideoDataOutput?
    private var frontOutput: AVCaptureVideoDataOutput?
    private var rearConnection: AVCaptureConnection?
    private var frontConnection: AVCaptureConnection?

    // Video-queue only, guarded by frameLock so stop can drop them after callbacks drain.
    private var rearSample: CMSampleBuffer?
    private var frontSample: CMSampleBuffer?

    // conversionLock only.
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    private var outputBuffer: CVPixelBuffer?
    private var videoFrame = OTVideoFrame(format: OTVideoFormat(argbWithWidth: 0, height: 0))

    // controlLock only.
    private var storedVideoContentHint: OTVideoContentHint = .none
    private var storedConsumer: OTVideoCaptureConsumer?
    private var capturing = false
    private var closed = false

    private static let sessionKey = DispatchSpecificKey<UInt8>()
    private static let sessionToken: UInt8 = 1
    private static let videoKey = DispatchSpecificKey<UInt8>()
    private static let videoToken: UInt8 = 1

    override init() {
        super.init()
        sessionQueue.setSpecific(key: Self.sessionKey, value: Self.sessionToken)
        videoQueue.setSpecific(key: Self.videoKey, value: Self.videoToken)
    }

    deinit {
        controlLock.withLock {
            capturing = false
            closed = true
            storedConsumer = nil
        }
        if DispatchQueue.getSpecific(key: Self.sessionKey) == Self.sessionToken {
            teardownSession()
        } else {
            sessionQueue.sync { self.teardownSession() }
        }
    }

    var videoContentHint: OTVideoContentHint {
        get { controlLock.withLock { storedVideoContentHint } }
        set { controlLock.withLock { storedVideoContentHint = newValue } }
    }

    var videoCaptureConsumer: OTVideoCaptureConsumer? {
        get { controlLock.withLock { storedConsumer } }
        set { controlLock.withLock { storedConsumer = newValue } }
    }

    func initCapture() {}

    func releaseCapture() {
        controlLock.withLock {
            closed = true
            capturing = false
            storedConsumer = nil
        }
        _ = stop()
    }

    func start() -> Int32 {
        if controlLock.withLock({ closed }) { return -1 }
        var started = false
        performOnSessionQueue {
            if self.session == nil {
                do {
                    try self.buildSession()
                } catch {
                    return
                }
            }
            guard let session = self.session else { return }
            if !session.isRunning {
                session.startRunning()
            }
            started = session.isRunning
        }
        guard started else { return -1 }
        controlLock.withLock { capturing = true }
        startOrientationUpdates()
        return 0
    }

    func stop() -> Int32 {
        controlLock.withLock { capturing = false }
        stopOrientationUpdates()
        performOnSessionQueue {
            self.teardownSession()
        }
        performOnVideoQueue {
            self.frameLock.withLock {
                self.rearSample = nil
                self.frontSample = nil
            }
        }
        return 0
    }

    func isCaptureStarted() -> Bool {
        controlLock.withLock { capturing }
    }

    func captureSettings(_ videoFormat: OTVideoFormat) -> Int32 {
        videoFormat.pixelFormat = .ARGB
        return 0
    }

    fileprivate func ingest(_ sampleBuffer: CMSampleBuffer, from camera: DualCaptureCamera) {
        frameLock.withLock {
            switch camera {
            case .rear: rearSample = sampleBuffer
            case .front: frontSample = sampleBuffer
            }
        }
        guard conversionLock.try() else { return }
        defer { conversionLock.unlock() }
        guard let consumer = reservedConsumer() else { return }
        let samples = frameLock.withLock { (rearSample, frontSample) }
        guard let rear = samples.0, let rearBuffer = CMSampleBufferGetImageBuffer(rear) else { return }
        let frontBuffer = samples.1.flatMap { CMSampleBufferGetImageBuffer($0) }
        render(
            rear: rearBuffer,
            front: frontBuffer,
            timestamp: CMSampleBufferGetPresentationTimeStamp(rear),
            to: consumer
        )
    }

    private func render(
        rear: CVPixelBuffer,
        front: CVPixelBuffer?,
        timestamp: CMTime,
        to consumer: OTVideoCaptureConsumer
    ) {
        let size = DualCaptureCompositor.outputSize(
            width: CVPixelBufferGetWidth(rear),
            height: CVPixelBufferGetHeight(rear)
        )
        guard let output = outputPixelBuffer(width: size.width, height: size.height) else { return }
        DualCaptureCompositor.render(
            rear: rear,
            front: front,
            into: output,
            showsFront: front != nil,
            context: ciContext
        )
        deliver(output, timestamp: timestamp, to: consumer)
    }

    private func deliver(_ buffer: CVPixelBuffer, timestamp: CMTime, to consumer: OTVideoCaptureConsumer) {
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        prepareFrame(width: width, height: height, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer))
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return }
        videoFrame.timestamp = timestamp
        videoFrame.orientation = .up
        videoFrame.format?.estimatedCaptureDelay = 100
        let planes = NSPointerArray(options: .opaqueMemory)
        planes.addPointer(base)
        videoFrame.planes = planes
        consumer.consumeFrame(videoFrame)
    }

    private func prepareFrame(width: Int, height: Int, bytesPerRow: Int) {
        let format = videoFrame.format
        let currentRow = (format?.bytesPerRow.firstObject as? NSNumber)?.intValue
        guard format == nil
            || format?.imageWidth != UInt32(width)
            || format?.imageHeight != UInt32(height)
            || currentRow != bytesPerRow
        else { return }
        let newFormat = OTVideoFormat(argbWithWidth: UInt32(width), height: UInt32(height))
        newFormat.bytesPerRow.removeAllObjects()
        newFormat.bytesPerRow.addObjects(from: [bytesPerRow])
        videoFrame = OTVideoFrame(format: newFormat)
    }

    private func outputPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        if let outputBuffer,
            CVPixelBufferGetWidth(outputBuffer) == width,
            CVPixelBufferGetHeight(outputBuffer) == height
        {
            return outputBuffer
        }
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: false,
                kCVPixelBufferCGBitmapContextCompatibilityKey: false,
            ] as CFDictionary,
            &buffer
        )
        guard status == kCVReturnSuccess else { return nil }
        outputBuffer = buffer
        return buffer
    }

    private func reservedConsumer() -> OTVideoCaptureConsumer? {
        controlLock.withLock {
            guard capturing, !closed else { return nil }
            return storedConsumer
        }
    }

    private func startOrientationUpdates() {
        let watcher = orientationWatcher
        let applyAngle: @Sendable (CGFloat) -> Void = { [weak self] angle in
            self?.performOnSessionQueue {
                self?.applyRotation(angle)
            }
        }
        let begin: @Sendable () -> Void = {
            MainActor.assumeIsolated {
                watcher.start(onAngle: applyAngle)
            }
        }
        if Thread.isMainThread {
            begin()
        } else {
            DispatchQueue.main.async(execute: begin)
        }
    }

    private func stopOrientationUpdates() {
        let watcher = orientationWatcher
        let end: @Sendable () -> Void = {
            MainActor.assumeIsolated {
                watcher.stop()
            }
        }
        if Thread.isMainThread {
            end()
        } else {
            DispatchQueue.main.async(execute: end)
        }
    }

    private func applyRotation(_ angle: CGFloat) {
        for connection in [rearConnection, frontConnection] {
            guard let connection, connection.isVideoRotationAngleSupported(angle) else { continue }
            connection.videoRotationAngle = angle
        }
    }

    private func buildSession() throws {
        guard let rearDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        else { throw DualCaptureSessionError.camerasUnavailable }

        let attempts: [(rear: Int32, front: Int32)] = [(1920, 1280), (1280, 640)]
        var lastError: Error = DualCaptureSessionError.cannotConfigure
        for attempt in attempts {
            do {
                let built = try makeSession(
                    rearDevice: rearDevice,
                    frontDevice: frontDevice,
                    rearMaxWidth: attempt.rear,
                    frontMaxWidth: attempt.front
                )
                guard built.session.hardwareCost <= 1 else {
                    built.detachDelegates()
                    lastError = DualCaptureSessionError.overBudget
                    continue
                }
                session = built.session
                rearOutput = built.rearOutput
                frontOutput = built.frontOutput
                rearConnection = built.rearConnection
                frontConnection = built.frontConnection
                applyRotation(90)
                return
            } catch {
                lastError = error
            }
        }
        throw lastError
    }

    private func makeSession(
        rearDevice: AVCaptureDevice,
        frontDevice: AVCaptureDevice,
        rearMaxWidth: Int32,
        frontMaxWidth: Int32
    ) throws -> BuiltSession {
        let session = AVCaptureMultiCamSession()
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.automaticallyConfiguresApplicationAudioSession = false

        let rearInput = try AVCaptureDeviceInput(device: rearDevice)
        let frontInput = try AVCaptureDeviceInput(device: frontDevice)
        guard session.canAddInput(rearInput), session.canAddInput(frontInput) else {
            throw DualCaptureSessionError.cannotConfigure
        }
        session.addInputWithNoConnections(rearInput)
        session.addInputWithNoConnections(frontInput)

        let rearAdapter = CameraSampleAdapter(camera: .rear, owner: self)
        let frontAdapter = CameraSampleAdapter(camera: .front, owner: self)
        let rearData = videoOutput(delegate: rearAdapter)
        let frontData = videoOutput(delegate: frontAdapter)
        guard session.canAddOutput(rearData), session.canAddOutput(frontData) else {
            throw DualCaptureSessionError.cannotConfigure
        }
        session.addOutputWithNoConnections(rearData)
        session.addOutputWithNoConnections(frontData)

        guard
            let rearPort = rearInput.ports(
                for: .video,
                sourceDeviceType: rearDevice.deviceType,
                sourceDevicePosition: .back
            ).first,
            let frontPort = frontInput.ports(
                for: .video,
                sourceDeviceType: frontDevice.deviceType,
                sourceDevicePosition: .front
            ).first
        else {
            throw DualCaptureSessionError.cannotConfigure
        }

        let rearConnection = AVCaptureConnection(inputPorts: [rearPort], output: rearData)
        let frontConnection = AVCaptureConnection(inputPorts: [frontPort], output: frontData)
        guard session.canAddConnection(rearConnection), session.canAddConnection(frontConnection) else {
            throw DualCaptureSessionError.cannotConfigure
        }
        session.addConnection(rearConnection)
        session.addConnection(frontConnection)
        mirrorFrontCamera(frontConnection)
        try applyFormat(on: rearDevice, maxWidth: rearMaxWidth)
        try applyFormat(on: frontDevice, maxWidth: frontMaxWidth)
        return BuiltSession(
            session: session,
            rearOutput: rearData,
            frontOutput: frontData,
            rearConnection: rearConnection,
            frontConnection: frontConnection
        )
    }

    private func videoOutput(delegate: CameraSampleAdapter) -> AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        output.setSampleBufferDelegate(delegate, queue: videoQueue)
        return output
    }

    private func mirrorFrontCamera(_ connection: AVCaptureConnection) {
        guard connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = true
    }

    private func applyFormat(on device: AVCaptureDevice, maxWidth: Int32) throws {
        guard let format = format(for: device, maxWidth: maxWidth) else {
            throw DualCaptureSessionError.cannotConfigure
        }
        try device.lockForConfiguration()
        defer { device.unlockForConfiguration() }
        device.activeFormat = format
        let frameDuration = CMTime(value: 1, timescale: 24)
        let supportsFrameRate = format.videoSupportedFrameRateRanges.contains { range in
            range.minFrameRate <= 24 && range.maxFrameRate >= 24
        }
        guard supportsFrameRate else { return }
        device.activeVideoMinFrameDuration = frameDuration
        device.activeVideoMaxFrameDuration = frameDuration
    }

    private func format(for device: AVCaptureDevice, maxWidth: Int32) -> AVCaptureDevice.Format? {
        let candidates = device.formats.filter { format in
            guard format.isMultiCamSupported else { return false }
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dimensions.width <= maxWidth && dimensions.width > 0
        }
        return candidates.max { lhs, rhs in
            let left = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
            let right = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
            return left.width * left.height < right.width * right.height
        }
    }

    private func teardownSession() {
        rearOutput?.setSampleBufferDelegate(nil, queue: nil)
        frontOutput?.setSampleBufferDelegate(nil, queue: nil)
        session?.stopRunning()
        session = nil
        rearOutput = nil
        frontOutput = nil
        rearConnection = nil
        frontConnection = nil
    }

    private func performOnSessionQueue(_ work: @Sendable () -> Void) {
        if DispatchQueue.getSpecific(key: Self.sessionKey) == Self.sessionToken {
            work()
        } else {
            sessionQueue.sync(execute: work)
        }
    }

    private func performOnVideoQueue(_ work: @Sendable () -> Void) {
        if DispatchQueue.getSpecific(key: Self.videoKey) == Self.videoToken {
            work()
        } else {
            videoQueue.sync(execute: work)
        }
    }

    private struct BuiltSession {
        let session: AVCaptureMultiCamSession
        let rearOutput: AVCaptureVideoDataOutput
        let frontOutput: AVCaptureVideoDataOutput
        let rearConnection: AVCaptureConnection
        let frontConnection: AVCaptureConnection

        func detachDelegates() {
            rearOutput.setSampleBufferDelegate(nil, queue: nil)
            frontOutput.setSampleBufferDelegate(nil, queue: nil)
        }
    }

    private final class CameraSampleAdapter: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate,
        @unchecked Sendable
    {
        let camera: DualCaptureCamera
        weak var owner: DualCaptureVideoCapturer?

        init(camera: DualCaptureCamera, owner: DualCaptureVideoCapturer) {
            self.camera = camera
            self.owner = owner
        }

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            _ = output
            _ = connection
            owner?.ingest(sampleBuffer, from: camera)
        }
    }
}
