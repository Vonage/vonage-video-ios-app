//
//  Created by Vonage on 26/2/26.
//

import Foundation
import OpenTok
import ReplayKit

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
/// 3. Once the session connects (`sessionDidConnect`), a `OTPublisher` with a
///    `ScreenShareVideoCapturer` is created and published as a screen-share stream.
///
/// ## Memory
/// The extension process has a hard ~50 MB memory ceiling. The custom capturer
/// passes frames directly to the SDK without extra copies; keep resolution ≤ 1280 px
/// on the longest edge when downscaling is needed.
///
/// - SeeAlso: ``ScreenShareVideoCapturer``, ``ScreenShareCredentialsStore``
final class SampleHandler: RPBroadcastSampleHandler {

    private var session: OTSession?
    private var publisher: OTPublisher?
    private let videoCapturer = ScreenShareVideoCapturer()
    
    // MARK: - Broadcast lifecycle

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        guard let store = ScreenShareCredentialsStore() else {
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "App Group is not configured."]))
            return
        }

        guard let credentials = store.load() else {
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No active VERA call found. Start a call before sharing your screen."]))
            return
        }

        let settings = OTSessionSettings()
        settings.singlePeerConnection = true
        settings.sessionMigration = true

        guard let otSession = OTSession(
            applicationId: credentials.applicationId,
            sessionId: credentials.sessionId,
            delegate: self,
            settings: settings
        ) else {
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
            finishBroadcastWithError(connectError)
        }
    }

    override func broadcastPaused() {
        publisher?.publishVideo = false
    }

    override func broadcastResumed() {
        publisher?.publishVideo = true
    }

    override func broadcastFinished() {
        var error: OTError?
        session?.disconnect(&error)
        session = nil
        publisher = nil
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
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
        videoCapturer.sessionDidConnect()
        let settings = OTPublisherSettings()
        settings.name = "screenshare"
        settings.publisherAudioFallbackEnabled = false
        guard let otPublisher = OTPublisher(delegate: self, settings: settings) else { return }
        otPublisher.videoType = .screen
        otPublisher.videoCapture = videoCapturer
        otPublisher.videoCapture?.videoContentHint = .text
        
        self.publisher = otPublisher

        var error: OTError?
        session.publish(otPublisher, error: &error)
    }

    func sessionDidDisconnect(_ session: OTSession) {
        videoCapturer.sessionDidDisconnect()
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {
        videoCapturer.sessionDidDisconnect()
        finishBroadcastWithError(error)
    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {}
    func session(_ session: OTSession, streamDestroyed stream: OTStream) {}
}

// MARK: - OTPublisherDelegate

extension SampleHandler: OTPublisherDelegate {
    func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        finishBroadcastWithError(error)
    }

    func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {}
    func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {}
}
