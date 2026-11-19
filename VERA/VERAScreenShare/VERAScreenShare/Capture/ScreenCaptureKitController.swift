//
//  Created by Vonage on 19/11/26.
//

#if canImport(ScreenCaptureKit)
    import CoreMedia
    import CoreVideo
    import Foundation
    import OSLog
    import ScreenCaptureKit
    import os

    /// In-process screen capture for iOS 27.
    ///
    /// The meeting-room button presents `SCContentSharingPicker`. This type uses the
    /// ScreenCaptureKit surface that also exists on macOS 14.6, so the multiplatform
    /// test target can typecheck it. `ScreenCaptureControllerFactory` instantiates it
    /// on iOS 27 only.
    ///
    /// iOS 27 can set the output size and start a new stream from `present()`. It cannot
    /// update a running stream or present the picker for an existing one. Those calls stay
    /// on the macOS slice.
    @available(iOS 27, macOS 14.6, *)
    final class ScreenCaptureKitController: NSObject, ScreenCaptureControlling, @unchecked Sendable {
        private let logger = Logger(subsystem: "com.vonage.vera", category: "ScreenCapture")
        private let sampleQueue = DispatchQueue(label: "com.vonage.VERA.screenshare.capture")
        private let consumerLock = OSAllocatedUnfairLock<(any ScreenShareFrameConsuming & Sendable)?>(initialState: nil)

        /// Touched only on the main queue.
        nonisolated(unsafe) private var stream: SCStream?
        nonisolated(unsafe) private var isActivated = false
        /// Stops caused by replacing an iOS stream. Those must not end the published share.
        nonisolated(unsafe) private var ignoredStopCount = 0

        func activate() {
            performOnMainSync { [self] in
                guard !isActivated else { return }
                let picker = SCContentSharingPicker.shared
                picker.add(self)
                #if os(macOS)
                    picker.maximumStreamCount = 0
                #endif
                picker.isActive = true
                isActivated = true
            }
        }

        func deactivate() {
            performOnMainSync { [self] in
                guard isActivated else { return }
                let picker = SCContentSharingPicker.shared
                picker.isActive = false
                picker.remove(self)
                isActivated = false
                let consumer = consumerLock.withLock { $0 }
                consumerLock.withLock { $0 = nil }
                stopStreamOnMain()
                consumer?.captureDidStop()
            }
        }

        func presentPicker() {
            performOnMainSync {
                let picker = SCContentSharingPicker.shared
                guard picker.isActive else { return }
                #if os(macOS)
                    if let stream = self.stream {
                        picker.present(for: stream)
                        return
                    }
                #endif
                picker.present()
            }
        }

        func setFrameConsumer(_ consumer: (any ScreenShareFrameConsuming & Sendable)?) {
            consumerLock.withLock { $0 = consumer }
        }

        private func performOnMainSync(_ work: @escaping @Sendable () -> Void) {
            if Thread.isMainThread {
                work()
            } else {
                DispatchQueue.main.sync(execute: work)
            }
        }

        private func apply(filter: SCContentFilter) {
            dispatchPrecondition(condition: .onQueue(.main))
            let configuration = makeConfiguration(for: filter)
            #if os(macOS)
                if let stream {
                    stream.updateContentFilter(filter) { error in
                        guard let error else { return }
                        let message = error.localizedDescription
                        DispatchQueue.main.async { [weak self] in
                            self?.logger.error("Screen capture filter update failed: \(message, privacy: .public)")
                        }
                    }
                    stream.updateConfiguration(configuration) { error in
                        guard let error else { return }
                        let message = error.localizedDescription
                        DispatchQueue.main.async { [weak self] in
                            self?.logger.error(
                                "Screen capture configuration update failed: \(message, privacy: .public)")
                        }
                    }
                    return
                }
            #else
                if let stream {
                    ignoredStopCount += 1
                    self.stream = nil
                    stream.stopCapture { _ in }
                }
            #endif

            let newStream = SCStream(filter: filter, configuration: configuration, delegate: self)
            do {
                try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            } catch {
                logger.error(
                    "Could not add the screen capture output: \(error.localizedDescription, privacy: .public)")
                return
            }
            stream = newStream
            let consumer = consumerLock.withLock { $0 }
            consumer?.captureWillStart()
            newStream.startCapture { [weak self] error in
                guard let error else { return }
                let nsError = error as NSError
                let message = nsError.localizedDescription
                let domain = nsError.domain
                let code = nsError.code
                DispatchQueue.main.async { [weak self] in
                    self?.handleStartFailure(domain: domain, code: code, message: message)
                }
            }
        }

        private func makeConfiguration(for filter: SCContentFilter) -> SCStreamConfiguration {
            let size = ScreenShareFrameSize.outputSize(
                contentRect: filter.contentRect,
                pointPixelScale: CGFloat(filter.pointPixelScale))
            let configuration = SCStreamConfiguration()
            configuration.width = size.width
            configuration.height = size.height
            configuration.capturesAudio = false
            #if os(macOS)
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                configuration.showsCursor = true
                configuration.scalesToFit = true
                configuration.preservesAspectRatio = true
                configuration.minimumFrameInterval = CMTime(value: 1, timescale: 15)
                configuration.queueDepth = 5
            #endif
            return configuration
        }

        private func handleStartFailure(domain: String, code: Int, message: String) {
            dispatchPrecondition(condition: .onQueue(.main))
            if isExpectedStop(domain: domain, code: code) {
                logger.debug("Screen capture start ended")
            } else {
                logger.error("Screen capture failed to start: \(message, privacy: .public)")
            }
            stopStreamOnMain()
            consumerLock.withLock { $0 }?.captureDidStop()
        }

        private func handleStreamStopped(domain: String, code: Int, message: String) {
            dispatchPrecondition(condition: .onQueue(.main))
            stream = nil
            if isExpectedStop(domain: domain, code: code) {
                logger.debug("Screen capture stopped")
            } else {
                logger.error("Screen capture stopped: \(message, privacy: .public)")
            }
            consumerLock.withLock { $0 }?.captureDidStop()
        }

        private func stopStreamOnMain() {
            dispatchPrecondition(condition: .onQueue(.main))
            guard let stream else { return }
            self.stream = nil
            stream.stopCapture { _ in }
        }

        private func isExpectedStop(domain: String, code: Int) -> Bool {
            guard domain == SCStreamErrorDomain else { return false }
            if code == SCStreamError.Code.userStopped.rawValue { return true }
            // SCStreamError.systemStoppedStream (-3821) is macOS 15+. Compare the code so this
            // file still typechecks for the macOS 14.6 test slice.
            return code == -3821
        }

        private func forwardableStatus(of sampleBuffer: CMSampleBuffer) -> Bool {
            guard
                let attachments = CMSampleBufferGetSampleAttachmentsArray(
                    sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
                let value = attachments.first?[.status]
            else { return false }
            let raw: Int? = {
                if let number = value as? NSNumber { return number.intValue }
                return value as? Int
            }()
            guard let raw, let status = SCFrameStatus(rawValue: raw) else { return false }
            return status == .complete || status == .started
        }
    }

    @available(iOS 27, macOS 14.6, *)
    extension ScreenCaptureKitController: SCContentSharingPickerObserver {
        func contentSharingPicker(
            _ picker: SCContentSharingPicker,
            didCancelFor stream: SCStream?
        ) {}

        func contentSharingPicker(
            _ picker: SCContentSharingPicker,
            didUpdateWith filter: SCContentFilter,
            for stream: SCStream?
        ) {
            let boxed = UncheckedSendableBox(filter)
            DispatchQueue.main.async { [weak self] in
                self?.apply(filter: boxed.value)
            }
        }

        func contentSharingPickerStartDidFailWithError(_ error: Error) {
            let nsError = error as NSError
            let message = nsError.localizedDescription
            let domain = nsError.domain
            let code = nsError.code
            DispatchQueue.main.async { [weak self] in
                self?.handleStartFailure(domain: domain, code: code, message: message)
            }
        }
    }

    @available(iOS 27, macOS 14.6, *)
    extension ScreenCaptureKitController: SCStreamDelegate {
        func stream(_ stream: SCStream, didStopWithError error: Error) {
            let nsError = error as NSError
            let message = nsError.localizedDescription
            let domain = nsError.domain
            let code = nsError.code
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.ignoredStopCount > 0 {
                    self.ignoredStopCount -= 1
                    return
                }
                self.handleStreamStopped(domain: domain, code: code, message: message)
            }
        }
    }

    @available(iOS 27, macOS 14.6, *)
    extension ScreenCaptureKitController: SCStreamOutput {
        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            guard type == .screen else { return }
            guard CMSampleBufferIsValid(sampleBuffer), CMSampleBufferDataIsReady(sampleBuffer) else { return }
            guard forwardableStatus(of: sampleBuffer) else { return }
            let consumer = consumerLock.withLock { $0 }
            consumer?.consume(sampleBuffer: sampleBuffer)
        }
    }

    /// Carries a non-Sendable ScreenCaptureKit value onto the main queue.
    private final class UncheckedSendableBox<Value>: @unchecked Sendable {
        let value: Value
        init(_ value: Value) { self.value = value }
    }
#endif
