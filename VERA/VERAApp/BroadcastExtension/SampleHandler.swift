//
//  Created by Vonage on 26/2/26.
//

import Foundation
import OSLog
import OpenTok
import ReplayKit

/// Darwin notification name used to signal the broadcast extension to stop.
private let stopBroadcastNotificationName = "com.vonage.VERA.stopBroadcast" as CFString

/// Broadcast Upload Extension entry point.
///
/// Receives audio/video `CMSampleBuffer` frames from ReplayKit and publishes the
/// screen share stream to the same Vonage session as the host VERA application.
///
/// ## Credential flow
/// 1. The VERA app's `VonageScreenSharePlugin` writes `applicationId`, `sessionId`, and
///    `token` into the shared App Group (`group.com.vonage.VERA`) when the call connects.
/// 2. On `broadcastStarted(withSetupInfo:)` this handler reads those credentials and
///    opens its own `OTSession`.
/// 3. Once the session connects (`sessionDidConnect`), an `OTPublisherKit` with a
///    `ScreenShareVideoCapturer` is created and published as a screen-share stream.
///    `OTPublisherKit` (not `OTPublisher`) is used to avoid initialising default
///    camera/microphone capture, which is forbidden inside app extensions.
///
/// ## Memory
/// The extension process has a hard ~50 MB memory ceiling. The custom capturer
/// passes frames directly to the SDK without extra copies; keep resolution ≤ 1280 px
/// on the longest edge when downscaling is needed.
///
/// - SeeAlso: ``ScreenShareVideoCapturer``, ``ScreenShareCredentialsStore``
final class SampleHandler: RPBroadcastSampleHandler {

    private let logger = Logger(subsystem: "com.vonage.VERA.BroadcastExtension", category: "SampleHandler")

    private var session: OTSession?
    private var publisher: OTPublisherKit?
    private let videoCapturer = ScreenShareVideoCapturer()
    private var didTearDown = false

    // MARK: - Broadcast lifecycle

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        logger.debug("broadcastStarted")

        guard let store = ScreenShareCredentialsStore() else {
            logger.error("App Group is not configured.")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "App Group is not configured."]))
            return
        }

        guard let credentials = store.load() else {
            logger.error("No active VERA call found.")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No active VERA call found. Start a call before sharing your screen."
                    ]))
            return
        }

        logger.debug("Credentials loaded — sessionId: \(credentials.sessionId, privacy: .public)")

        registerStopBroadcastNotification()

        let settings = OTSessionSettings()
        settings.singlePeerConnection = true

        guard
            let otSession = OTSession(
                applicationId: credentials.applicationId,
                sessionId: credentials.sessionId,
                delegate: self,
                settings: settings
            )
        else {
            logger.error("Failed to create OTSession.")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create Vonage session."]))
            return
        }

        self.session = otSession

        var connectError: OTError?
        otSession.connect(withToken: credentials.token, error: &connectError)

        if let connectError {
            logger.error("OTSession connect failed: \(connectError.localizedDescription)")
            finishBroadcastWithError(connectError)
        }
    }

    override func broadcastPaused() {
        logger.debug("broadcastPaused")
        publisher?.publishVideo = false
    }

    override func broadcastResumed() {
        logger.debug("broadcastResumed")
        publisher?.publishVideo = true
    }

    override func broadcastFinished() {
        logger.debug("broadcastFinished")

        tearDown()
    }

    /// Register observer for stop notification from main app
    private func registerStopBroadcastNotification() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let handler = Unmanaged<SampleHandler>.fromOpaque(observer).takeUnretainedValue()
                handler.stopBroadcastFromNotification()
            },
            stopBroadcastNotificationName,
            nil,
            .deliverImmediately
        )
    }

    /// Called when the main app signals the broadcast should stop.
    private func stopBroadcastFromNotification() {
        logger.debug("Received stop broadcast notification from main app")

        DispatchQueue.main.async { [self] in
            self.tearDown()
            self.finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "The call has ended."]))
        }
    }

    /// Tears down the Vonage session and removes the Darwin notification observer.
    /// Guarded against reentrancy — safe to call multiple times.
    private func tearDown() {
        guard !didTearDown else { return }
        didTearDown = true

        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(stopBroadcastNotificationName),
            nil
        )

        var error: OTError?
        session?.disconnect(&error)
        if let error {
            logger.error("OTSession disconnect error: \(error.localizedDescription)")
        }
        session = nil
        publisher = nil
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        switch sampleBufferType {
        case .video:
            videoCapturer.consumeVideoSampleBuffer(sampleBuffer)
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - OTSessionDelegate

extension SampleHandler: OTSessionDelegate {

    func sessionDidConnect(_ session: OTSession) {
        logger.debug("sessionDidConnect")
        videoCapturer.sessionDidConnect()

        let settings = OTPublisherSettings()
        settings.name = "screenshare"
        settings.publisherAudioFallbackEnabled = false

        /// Use an `OTPublisherKit` instead of a `OTPublisher`. `OTPublisher` initializes default
        /// camera/microphone capture hardware, which is forbidden in broadcast extensions — causing the
        /// extension to hang and get killed by ReplayKit after a 5-second timeout.
        guard let otPublisher = OTPublisherKit(delegate: self, settings: settings) else {
            logger.error("Failed to create OTPublisherKit.")
            return
        }
        otPublisher.videoType = .screen
        otPublisher.videoCapture = videoCapturer
        otPublisher.videoCapture?.videoContentHint = .text
        otPublisher.publishAudio = false

        self.publisher = otPublisher

        var error: OTError?
        session.publish(otPublisher, error: &error)
        if let error {
            logger.error("OTSession publish failed: \(error.localizedDescription)")
        }
    }

    func sessionDidDisconnect(_ session: OTSession) {
        logger.debug("sessionDidDisconnect")
        videoCapturer.sessionDidDisconnect()
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        logger.error("session didFailWithError: \(error.localizedDescription)")
        videoCapturer.sessionDidDisconnect()
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {
        logger.debug("streamCreated: \(stream.streamId)")
    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        logger.debug("streamDestroyed: \(stream.streamId)")
    }
}

// MARK: - OTPublisherDelegate

extension SampleHandler: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        logger.error("publisher didFailWithError: \(error.localizedDescription)")
        finishBroadcastWithError(error)
    }

    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        logger.debug("publisher streamCreated: \(stream.streamId)")
    }

    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        logger.debug("publisher streamDestroyed: \(stream.streamId)")
    }
}
