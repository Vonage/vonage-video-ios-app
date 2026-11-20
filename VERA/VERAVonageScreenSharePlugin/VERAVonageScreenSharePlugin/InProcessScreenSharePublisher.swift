//
//  Created by Vonage on 19/11/26.
//

import Foundation
import OSLog
import OpenTok
import VERAScreenShare

/// Publishes an in-process screen share on its own Vonage session.
///
/// A second session is what makes the share appear as its own participant. The camera
/// publisher on the call stays untouched. `OTPublisherKit` avoids opening the camera.
final class InProcessScreenSharePublisher: NSObject, ScreenShareFrameConsuming, @unchecked Sendable {
    private let logger = Logger(subsystem: "com.vonage.vera", category: "ScreenShare")
    private let credentials: ScreenShareCredentials
    private let capturer = InProcessScreenShareCapturer()

    /// Session and publisher are used on the main queue.
    nonisolated(unsafe) private var session: OTSession?
    nonisolated(unsafe) private var publisher: OTPublisherKit?
    nonisolated(unsafe) private var didStop = false

    init(credentials: ScreenShareCredentials) {
        self.credentials = credentials
        super.init()
    }

    func consume(sampleBuffer: CMSampleBuffer) {
        capturer.consumeVideoSampleBuffer(sampleBuffer)
    }

    func captureWillStart() {
        performOnMainSync { [self] in
            startOnMain()
        }
    }

    func captureDidStop() {
        performOnMainSync { [self] in
            stopOnMain()
        }
    }

    private func performOnMainSync(_ work: @escaping @Sendable () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    private func startOnMain() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard session == nil, !didStop else { return }

        let settings = OTSessionSettings()
        settings.singlePeerConnection = true
        guard
            let otSession = OTSession(
                applicationId: credentials.applicationId,
                sessionId: credentials.sessionId,
                delegate: self,
                settings: settings)
        else {
            logger.error("Failed to create the screen share session.")
            return
        }

        otSession.apiQueue = .main
        session = otSession

        var connectError: OTError?
        otSession.connect(withToken: credentials.token, error: &connectError)
        if let connectError {
            logger.error("Screen share connect failed: \(connectError.localizedDescription, privacy: .public)")
            stopOnMain()
        }
    }

    private func publishOnMain() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !didStop, let session else { return }
        capturer.sessionDidConnect()

        let settings = OTPublisherSettings()
        settings.scalableScreenshare = true
        settings.videoCodecPreference = .manual(withCodecs: [
            NSNumber(value: OTVideoCodecType.H264.rawValue),
            NSNumber(value: OTVideoCodecType.VP8.rawValue),
        ])
        if !credentials.username.isEmpty {
            settings.name = credentials.username
        }
        settings.publisherAudioFallbackEnabled = false

        guard let otPublisher = OTPublisherKit(delegate: self, settings: settings) else {
            logger.error("Failed to create the screen share publisher.")
            stopOnMain()
            return
        }
        otPublisher.videoType = .screen
        otPublisher.videoCapture = capturer
        otPublisher.videoCapture?.videoContentHint = .text
        otPublisher.publishAudio = false
        otPublisher.publishVideo = true
        publisher = otPublisher

        var error: OTError?
        session.publish(otPublisher, error: &error)
        if let error {
            logger.error("Screen share publish failed: \(error.localizedDescription, privacy: .public)")
            stopOnMain()
        }
    }

    private func stopOnMain() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard !didStop else { return }
        didStop = true
        capturer.close()
        var error: OTError?
        session?.disconnect(&error)
        if let error {
            logger.error("Screen share disconnect failed: \(error.localizedDescription, privacy: .public)")
        }
        session = nil
        publisher = nil
    }
}

extension InProcessScreenSharePublisher: OTSessionDelegate {
    func sessionDidConnect(_: OTSession) {
        performOnMainSync { [self] in
            publishOnMain()
        }
    }

    func sessionDidDisconnect(_: OTSession) {
        capturer.sessionDidDisconnect()
    }

    func session(_: OTSession, didFailWithError error: OTError) {
        let message = error.localizedDescription
        DispatchQueue.main.async { [self] in
            self.logger.error("Screen share session failed: \(message, privacy: .public)")
            self.stopOnMain()
        }
    }

    func session(_: OTSession, streamCreated _: OTStream) {
        // This session only publishes the screen. It does not subscribe to other streams.
    }

    func session(_: OTSession, streamDestroyed _: OTStream) {
        // This session only publishes the screen. A remote stream ending does not stop the share.
    }
}

extension InProcessScreenSharePublisher: OTPublisherDelegate {
    func publisher(_: OTPublisherKit, didFailWithError error: OTError) {
        let message = error.localizedDescription
        DispatchQueue.main.async { [self] in
            self.logger.error("Screen share publisher failed: \(message, privacy: .public)")
            self.stopOnMain()
        }
    }

    func publisher(_: OTPublisherKit, streamCreated _: OTStream) {
        logger.debug("Screen share stream created")
    }

    func publisher(_: OTPublisherKit, streamDestroyed _: OTStream) {
        logger.debug("Screen share stream destroyed")
    }
}
