//
//  Created by Vonage on 26/2/26.
//

import Foundation
import OSLog
import OpenTok
import ReplayKit
import VERAScreenShare

/// Darwin notification name used to signal the broadcast extension to stop.
private var stopBroadcastNotificationName: CFString { "com.vonage.VERA.stopBroadcast" as CFString }

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
/// passes frames directly to the SDK without extra copies; the default capture policy caps the longest edge at 1280 px. Higher explicit
/// output bounds require memory validation on a physical device.
///
/// - SeeAlso: ``ScreenShareVideoCapturer``, ``ScreenShareCredentialsStore``
final class BroadcastSampleHandler: RPBroadcastSampleHandler {
    private let videoCapturer: ScreenShareVideoCapturer
    private let controlOwner: BroadcastControlOwner

    override init() {
        let videoSettings = Self.loadVideoSettings()
        let capturer = ScreenShareVideoCapturer(settings: videoSettings)
        let finisher = ReplayKitFinishBridge()
        videoCapturer = capturer
        controlOwner = BroadcastControlOwner(capturer: capturer, finisher: finisher, videoSettings: videoSettings)
        super.init()
        finisher.attach(self)
    }

    /// The extension process lives for one broadcast, so the app's policy is read once here.
    private static func loadVideoSettings() -> ScreenShareVideoSettings {
        guard let data = UserDefaults(suiteName: veraAppGroupIdentifier)?.data(forKey: ScreenSharingKeys.videoSettings),
            let settings = try? JSONDecoder().decode(ScreenShareVideoSettings.self, from: data)
        else { return ScreenShareVideoSettings() }
        return settings
    }

    deinit {
        videoCapturer.close()
        let owner = controlOwner
        DispatchQueue.main.async { owner.finish() }
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        let owner = controlOwner
        DispatchQueue.main.async { owner.start() }
    }

    override func broadcastPaused() {
        videoCapturer.setPaused(true)
        let owner = controlOwner
        DispatchQueue.main.async { owner.setPublisherPaused(true) }
    }

    override func broadcastResumed() {
        videoCapturer.setPaused(false)
        let owner = controlOwner
        DispatchQueue.main.async { owner.setPublisherPaused(false) }
    }

    override func broadcastFinished() {
        // Close admission on the ReplayKit callback queue. Its main-owner cleanup
        // then joins admitted consumer calls without retaining or transferring this handler.
        videoCapturer.close()
        let owner = controlOwner
        DispatchQueue.main.async { owner.finish() }
    }

    override func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        guard sampleBufferType == .video else { return }
        guard CMSampleBufferIsValid(sampleBuffer), CMSampleBufferDataIsReady(sampleBuffer) else { return }
        videoCapturer.consumeVideoSampleBuffer(sampleBuffer)
    }
}

/// The only ReplayKit interoperability escape hatch. The weak reference is set once
/// during handler initialization and accessed under a lock. It never leaves this bridge:
/// only the framework's finish method is invoked, synchronously on MainActor. No inherited
/// RPBroadcastSampleHandler state is asserted to be Sendable or exposed to worker tasks.
private final class ReplayKitFinishBridge: @unchecked Sendable {
    private let lock = NSLock()
    private weak var handler: RPBroadcastSampleHandler?

    func attach(_ handler: RPBroadcastSampleHandler) {
        lock.withLock { self.handler = handler }
    }

    @MainActor
    func finish(domain: String, code: Int, message: String) {
        let handler = lock.withLock { self.handler }
        handler?.finishBroadcastWithError(
            NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message]))
    }
}

/// Constructible from ReplayKit's initializer using only owned Sendable dependencies.
/// All lazily created SDK state stays inside the MainActor controller.
@MainActor
private final class BroadcastControlOwner {
    private let capturer: ScreenShareVideoCapturer
    private let finisher: ReplayKitFinishBridge
    private let videoSettings: ScreenShareVideoSettings
    private lazy var control = BroadcastControl(capturer: capturer, finisher: finisher, videoSettings: videoSettings)
    private var finishScheduled = false

    nonisolated init(
        capturer: ScreenShareVideoCapturer,
        finisher: ReplayKitFinishBridge,
        videoSettings: ScreenShareVideoSettings
    ) {
        self.capturer = capturer
        self.finisher = finisher
        self.videoSettings = videoSettings
    }

    func start() { control.startBroadcast() }
    func setPublisherPaused(_ paused: Bool) { control.setPublisherPaused(paused) }

    func finish() {
        guard !finishScheduled else { return }
        finishScheduled = true
        capturer.closeOnMainActor { [self] in control.tearDown() }
    }
}

@MainActor
private final class BroadcastControl: NSObject {
    nonisolated private let logger = Logger(
        subsystem: "com.vonage.VERA.BroadcastExtension", category: "BroadcastSampleHandler")
    nonisolated private let videoCapturer: ScreenShareVideoCapturer
    private let finisher: ReplayKitFinishBridge
    private let videoSettings: ScreenShareVideoSettings
    private var session: OTSession?
    private var publisher: OTPublisherKit?
    private var didTearDown = false
    private var store: UserDefaultsScreenShareCredentialsRepository?

    init(capturer: ScreenShareVideoCapturer, finisher: ReplayKitFinishBridge, videoSettings: ScreenShareVideoSettings) {
        videoCapturer = capturer
        self.finisher = finisher
        self.videoSettings = videoSettings
        super.init()
    }

    func setPublisherPaused(_ paused: Bool) {
        guard !didTearDown else { return }
        publisher?.publishVideo = !paused
    }

    private func finishBroadcastWithError(_ error: Error) {
        let description = error as NSError
        finisher.finish(domain: description.domain, code: description.code, message: description.localizedDescription)
    }

    func startBroadcast() {
        guard !didTearDown, !videoCapturer.isClosed else { return }
        logger.debug("broadcastStarted")

        registerStopBroadcastNotification()

        guard let userDefaults = UserDefaults(suiteName: veraAppGroupIdentifier) else {
            logger.error("App Group is not configured.")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "App Group is not configured."]))
            return
        }

        let store = UserDefaultsScreenShareCredentialsRepository(userDefaults: userDefaults)
        self.store = store

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

        otSession.apiQueue = .main
        self.session = otSession

        var connectError: OTError?
        otSession.connect(withToken: credentials.token, error: &connectError)

        if let connectError {
            logger.error("OTSession connect failed: \(connectError.localizedDescription)")
            finishBroadcastWithError(connectError)
        }
    }

    /// Register observer for stop notification from main app
    private func registerStopBroadcastNotification() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let handler = Unmanaged<BroadcastControl>.fromOpaque(observer).takeUnretainedValue()
                handler.stopBroadcastFromNotification()
            },
            stopBroadcastNotificationName,
            nil,
            .deliverImmediately
        )
    }

    /// Called when the main app signals the broadcast should stop.
    ///
    /// Only calls `finishBroadcastWithError` — ReplayKit will stop sending frames
    /// and then call `broadcastFinished()`, which performs the actual `tearDown()`.
    /// This avoids disconnecting the OTSession while frames are still arriving.
    nonisolated private func stopBroadcastFromNotification() {
        logger.debug("Received stop broadcast notification from main app")

        DispatchQueue.main.async { [self] in
            self.finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "The call has ended."]))
        }
    }

    /// Tears down the Vonage session and removes the Darwin notification observer.
    /// Guarded against reentrancy — safe to call multiple times.
    func tearDown() {
        guard !didTearDown else { return }
        didTearDown = true
        videoCapturer.close()

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

}

// MARK: - OTSessionDelegate

extension BroadcastControl: OTSessionDelegate {

    nonisolated func sessionDidConnect(_ session: OTSession) {
        // This private session is configured with apiQueue = .main before connecting.
        // Handle it inline so a later disconnect cannot overtake queued publication.
        MainActor.assumeIsolated {
            publishScreenShare()
        }
    }

    private func publishScreenShare() {
        guard !didTearDown, !videoCapturer.isClosed, let session else { return }
        logger.debug("sessionDidConnect")
        videoCapturer.sessionDidConnect()

        let settings = OTPublisherSettings()
        settings.scalableScreenshare = videoSettings.scalableScreenshare
        if let codecs = videoSettings.preferredCodecs {
            settings.videoCodecPreference = .manual(withCodecs: codecs.map { NSNumber(value: $0) })
        }

        if let credentials = store?.load(), !credentials.username.isEmpty {
            settings.name = "\(credentials.username)'s screen"
        } else {
            settings.name = "Screenshare"
        }

        settings.publisherAudioFallbackEnabled = false

        /// Use an `OTPublisherKit` instead of a `OTPublisher`. `OTPublisher` initializes default
        /// camera/microphone capture hardware, which is forbidden in broadcast extensions — causing the
        /// extension to hang and get killed by ReplayKit after a 5-second timeout.
        guard let otPublisher = OTPublisherKit(delegate: self, settings: settings) else {
            logger.error("Failed to create OTPublisherKit.")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "OTPublisherKit creation failed."]))
            return
        }
        otPublisher.videoType = .screen
        otPublisher.videoCapture = videoCapturer
        otPublisher.videoCapture?.videoContentHint = OTVideoContentHint(rawValue: videoSettings.contentHint) ?? .detail
        if let rawPreset = videoSettings.bitratePreset, let preset = OTVideoBitratePreset(rawValue: rawPreset) {
            if preset == .custom {
                otPublisher.maxVideoBitrate = max(5_000, min(videoSettings.maxVideoBitrate, 10_000_000))
            } else {
                otPublisher.videoBitratePreset = preset
            }
        }
        otPublisher.publishAudio = false
        otPublisher.publishVideo = !videoCapturer.isPaused

        self.publisher = otPublisher

        var error: OTError?
        session.publish(otPublisher, error: &error)
        if let error {
            logger.error("OTSession publish failed: \(error.localizedDescription)")
            finishBroadcastWithError(error)
        }
    }

    nonisolated func sessionDidDisconnect(_ session: OTSession) {
        logger.debug("sessionDidDisconnect")
        videoCapturer.sessionDidDisconnect()
    }

    nonisolated func session(_ session: OTSession, didFailWithError error: OTError) {
        videoCapturer.sessionDidDisconnect()
        finishAfterSDKFailure(message: error.localizedDescription, code: error.code)
    }

    nonisolated func session(_ session: OTSession, streamCreated stream: OTStream) {
        logger.debug("streamCreated: \(stream.streamId)")
    }

    nonisolated func session(_ session: OTSession, streamDestroyed stream: OTStream) {
        logger.debug("streamDestroyed: \(stream.streamId)")
    }
}

// MARK: - OTPublisherDelegate

extension BroadcastControl: OTPublisherDelegate {
    nonisolated func publisher(_ publisher: OTPublisherKit, didFailWithError error: OTError) {
        videoCapturer.sessionDidDisconnect()
        finishAfterSDKFailure(message: error.localizedDescription, code: error.code)
    }

    nonisolated func publisher(_ publisher: OTPublisherKit, streamCreated stream: OTStream) {
        logger.debug("publisher streamCreated: \(stream.streamId)")
    }

    nonisolated func publisher(_ publisher: OTPublisherKit, streamDestroyed stream: OTStream) {
        logger.debug("publisher streamDestroyed: \(stream.streamId)")
    }
}

extension BroadcastControl {
    nonisolated private func finishAfterSDKFailure(message: String, code: Int) {
        // Copy diagnostic values while the SDK-owned error is borrowed; never enqueue it.
        DispatchQueue.main.async { [weak self] in
            guard let self, !didTearDown else { return }
            logger.error("Broadcast SDK failure: \(message)")
            finishBroadcastWithError(
                NSError(
                    domain: "VERABroadcastExtension",
                    code: code,
                    userInfo: [NSLocalizedDescriptionKey: message]))
        }
    }
}
