//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import OpenTok
import VERACore
import VERADomain

/// A concrete implementation of ``CallFacade`` that orchestrates Vonage video calling sessions.
///
/// `VonageCall` serves as the central coordinator for video call management in the VERA application,
/// bridging the Vonage SDK with the application's domain layer. It manages the complete lifecycle
/// of calls: session connection, local publishing, remote subscriptions, media control, and plugin integration.
///
/// ## Overview
///
/// This class implements the Facade pattern to provide a unified interface for video calling.
/// It coordinates:
/// - Session management through ``VonageSession``
/// - Local media publishing through ``VonagePublisher``
/// - Remote participant subscriptions through `VonageSubscriber`
/// - Reactive state observation via Combine publishers
/// - Optional extensibility via the plugin system
public final class VonageCall: CallFacade {

    private var cancellables = Set<AnyCancellable>()
    /// Dedicated cancellable set for publisher observation.
    /// Cleared and rebuilt every time the publisher is replaced so stale subscriptions
    /// from the old publisher don't accumulate and cause redundant main-thread work.
    private var publisherCancellables = Set<AnyCancellable>()
    private let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)

    /// A publisher that emits the current participant state, never fails.
    ///
    /// Provides real-time updates about:
    /// - The local participant (if publishing)
    /// - The list of remote participants (subscribers)
    /// - The ID of the active speaker (if any)
    ///
    /// - Returns: ``ParticipantsState`` updates suitable for UI consumption.
    /// - Note: Emitted on the main thread; safe for UI updates.
    public lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    private var _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(SessionEvent.idle)

    /// A publisher that emits session-level events and errors, never fails.
    ///
    /// Subscribe to capture connection failures, stream errors, and plugin lifecycle issues.
    ///
    /// - Returns: A publisher that emits ``SessionEvent`` values.
    /// - Important: Always subscribe to handle errors surfaced during call operations.
    public lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    private var _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)

    /// A publisher for local media publishing state (audio/video), never fails.
    ///
    /// Emits when local audio/video publishing toggles change or when muted/unmuted in bulk.
    ///
    /// - Returns: ``SessionState`` reflecting `isPublishingAudio` and `isPublishingVideo`.
    public lazy var statePublisher: AnyPublisher<SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    private var _archivingState = CurrentValueSubject<ArchivingState, Never>(.idle)

    /// A publisher for call recording state, never fails.
    ///
    /// Emits ArchivingState events whenever the call recording state changes.
    ///
    /// - Returns: ``SessionState`` reflecting `isPublishingAudio` and `isPublishingVideo`.
    public lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    private var _captionsEnabled = CurrentValueSubject<Bool, Never>(false)

    /// A publisher for tracking captions state, never fails.
    ///
    /// Emits a boolean value whenever the captions have been activated or deactivated.
    ///
    /// - Returns: ``Bool`` reflecting `captionsEnabled`.
    public lazy var captionsEnabled: AnyPublisher<Bool, Never> = _captionsEnabled.eraseToAnyPublisher()

    private var _captionsPublisher = CurrentValueSubject<[CaptionItem], Never>([])

    /// A publisher for the captions list
    ///
    /// Emits a list of caption items whenever the captions state changes.
    ///
    /// - Returns: ``[CaptionItem]`` reflecting `captions` list.
    public lazy var captionsPublisher: AnyPublisher<[CaptionItem], Never> =
        Publishers.CombineLatest(captionsEnabled, _captionsPublisher)
        .map { isEnabled, captions in
            isEnabled ? captions : []
        }
        .eraseToAnyPublisher()

    /// Captions cleanup timer to clear captions after a certain period of inactivity.
    private var captionCleanupTimer: Timer?

    // MARK: - Network Stats

    /// Collects publisher and subscriber network stats from the SDK.
    private let statsCollector: StatsCollector

    /// Tracks whether network stats collection is currently active.
    private var isNetworkStatsEnabled = false

    /// A publisher that emits aggregated network statistics, never fails.
    ///
    /// Emits ``NetworkMediaStats/empty`` when stats collection is disabled.
    public lazy var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> =
        statsCollector.statsPublisher

    /// A unique identifier for this call instance.
    ///
    /// Useful for logging, analytics, and correlating call-related operations.
    public let id = UUID()

    /// The credentials required to connect to the Vonage session.
    ///
    /// Contains the session ID, authentication token, and room name used during connection.
    public let credentials: RoomCredentials

    /// The Vonage session wrapper managing the connection and signals.
    public let session: VonageSession

    /// The publisher for the local participant's audio and video.
    ///
    /// Replaced during ``applyPublisherAdvancedSettings(_:)`` when SDK-level settings change.
    public private(set) var publisher: VonagePublisher

    /// The subscriber for the local participant's captions.
    public var publisherCaptions: VonageSubscriber?

    /// The participant representation of the local publisher, set after publishing.
    public var publisherParticipant: Participant?

    /// Repository used to recreate the publisher with new settings during ``applyPublisherAdvancedSettings(_:)``.
    private let publisherRepository: PublisherRepository

    private let subscriberFactory = VonageSubscriberFactory()

    private let activeSpeakerTracker = ActiveSpeakerTracker()
    private lazy var callStateManager = CallStateManager(
        activeSpeakerTracker: activeSpeakerTracker)

    /// The collection of plugins extending call functionality (e.g., chat, CallKit, recording).
    ///
    /// - SeeAlso: ``assignPlugins(_:)``, `VonageSignalEmitter`, `VonagePluginCallHolder`, `VonageSignalHandler`
    public var plugins: [any VonagePlugin] = []

    private var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)

    /// A publisher that emits the current connection state of the call, never fails.
    ///
    /// Possible states:
    /// - ``CallState/idle``: Not connected
    /// - ``CallState/connecting``: Attempting to connect
    /// - ``CallState/connected``: Active call
    /// - ``CallState/disconnecting``: Tearing down
    /// - ``CallState/disconnected``: Cleaned up
    ///
    /// - Returns: A publisher that emits ``CallState`` values.
    /// - Note: Use to drive connection-related UI.
    public lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    /// Initializes a new Vonage call instance.
    ///
    /// - Parameters:
    ///   - credentials: Room credentials with session ID, token, and room name.
    ///   - session: The Vonage session wrapper managing connectivity and signals.
    ///   - publisher: Local media publisher for audio/video.
    ///   - publisherRepository: Repository for recreating the publisher during settings changes.
    ///   - networkStatsCollector: Collect info of audio, video and rtc data
    /// - Important: Call ``setup()`` before ``connect()`` to configure handlers and observers.
    public init(
        credentials: RoomCredentials,
        session: VonageSession,
        publisher: VonagePublisher,
        publisherRepository: PublisherRepository,
        statsCollector: StatsCollector
    ) {
        self.credentials = credentials
        self.session = session
        self.publisher = publisher
        self.publisherRepository = publisherRepository
        self.statsCollector = statsCollector
    }

    /// Sets up the call by configuring session handlers and initializing observers.
    ///
    /// Establishes event handling for streams and session events, initializes media state,
    /// and starts active speaker tracking.
    ///
    /// - Important: Call exactly once per instance to avoid duplicate handlers.
    /// - SeeAlso: ``connect()``
    public func setup() {
        setupSessionHandlers()
        updateMediaState()
        setupActiveSpeakerObservation()
    }

    private func setupSessionHandlers() {
        session.onNewStream = { [weak self] stream in
            self?.addSubscriber(stream)
        }
        session.onStreamDestroyed = { [weak self] stream in
            self?.removeSubscriber(stream)
        }
        session.onSessionFailure = { [weak self] error in
            self?.sessionDidFail(error)
        }
        session.onSessionDidDisconnect = { [weak self] in
            self?.sessionDidDisconnect()
        }
        session.onSessionDidBeginReconnecting = { [weak self] in
            self?.sessionDidBeginReconnecting()
        }
        session.onSessionDidReconnect = { [weak self] in
            self?.sessionDidReconnect()
        }
        session.onSessionDidConnect = { [weak self] in
            self?.updateCallState(to: .connected)
            self?.publishToSession()
            Task { [weak self] in
                await self?.notifyCallDidStartToPlugins()
            }
        }
        session.onSessionSignal = { [weak self] signal in
            self?.handleSignal(signal)
        }
        session.onArchiveStarted = { [weak self] archiveID in
            self?._archivingState.value = .archiving(archiveID)

            do {
                let signal = try VonageSignal.archivingState(archiveID)
                self?.handleSignal(signal)
            } catch {
            }
        }
        session.onArchiveStopped = { [weak self] _ in
            self?._archivingState.value = .idle

            do {
                let signal = try VonageSignal.idleArchivingState()
                self?.handleSignal(signal)
            } catch {
            }
        }
    }

    private func updateParticipantsState(_ state: ParticipantsState) async {
        _participantsPublisher.value = .init(
            localParticipant: publisherParticipant,
            participants: state.participants,
            activeParticipantId: state.activeParticipantId
        )
    }

    private func updateCallState(to newState: CallState) {
        _callState.value = newState
    }

    // MARK: Publisher

    private func publishToSession() {
        guard !publisher.hasSession else { return }
        do {
            try session.publish(publisher: publisher)
            publisherParticipant = publisher.participant
            publisher.setup()
            setupPublisherObservation(publisher)
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupActiveSpeakerObservation() {
        activeSpeakerTracker.$activeSpeaker
            .removeDuplicates()
            .sink { _ in
                Task { [weak self] in
                    guard let self else { return }
                    let state = await self.callStateManager.getCurrentState()
                    await self.updateParticipantsState(state)
                }
            }
            .store(in: &cancellables)
    }

    private func setupPublisherObservation(_ publisher: VonagePublisher) {
        publisher.$participant
            .sink { [weak self] participant in
                guard let self = self else { return }
                self.publisherParticipant = participant

                let currentState = self._participantsPublisher.value

                let newState = ParticipantsState(
                    localParticipant: participant,
                    participants: currentState.participants,
                    activeParticipantId: currentState.activeParticipantId
                )
                Task { [weak self] in
                    await self?.updateParticipantsState(newState)
                }
            }
            .store(in: &publisherCancellables)
    }

    // MARK: Subscriber

    private func addSubscriber(_ stream: OTStream) {
        Task { [weak self] in
            guard let self else { return }
            await self.doSubscribe(stream)
        }
    }

    @MainActor
    private func doSubscribe(_ stream: OTStream) async {
        do {
            let vonageSubscriber = try subscriberFactory.makeSubscriber(stream)
            vonageSubscriber.onError = { [weak self] in
                self?.removeSubscriber(stream)
            }
            vonageSubscriber.onCaption = { [weak self] caption in
                self?.appendCaption(caption)
            }

            // Wire network stats delegate if collection is active
            if isNetworkStatsEnabled {
                vonageSubscriber.otSubscriber.networkStatsDelegate = statsCollector
                statsCollector.requestRtcStats(from: vonageSubscriber.otSubscriber)
            }

            setupSubscriberObservation(vonageSubscriber)
            setupAudioLevelObservation(vonageSubscriber)

            try session.subscribe(subscriber: vonageSubscriber)

            let state = await callStateManager.addSubscriber(vonageSubscriber)
            await updateParticipantsState(state)

            if areCaptionsEnabled {
                vonageSubscriber.enableCaptions()
            }
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func setupSubscriberObservation(_ subscriber: VonageSubscriber) {
        subscriber.$participant
            .sink { participant in
                Task { [weak self] in
                    guard let self = self else { return }
                    let state = await self.callStateManager.updateParticipant(participant)
                    await self.updateParticipantsState(state)
                }
            }
            .store(in: &cancellables)
    }

    private func setupAudioLevelObservation(_ subscriber: VonageSubscriber) {
        subscriber.$audioLevel
            .sink { audioLevel in
                Task { [weak self] in
                    guard let self = self else { return }
                    let speakerInfo = SpeakerInfo(
                        id: subscriber.participant.id,
                        audioLevel: audioLevel,
                        isMicEnabled: subscriber.participant.isMicEnabled
                    )
                    await self.callStateManager.updateActiveSpeaker(speakerInfo)
                }
            }
            .store(in: &cancellables)
    }

    private func removeSubscriber(_ stream: OTStream) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let (_, state) = await callStateManager.removeSubscriber(id: stream.streamId)
            // There is no need to do a session unsubscribe if the stream has been destroyed
            await self.updateParticipantsState(state)
        }
    }

    // MARK: Session

    /// Initiates the connection to the Vonage session.
    ///
    /// Transitions the call to the connecting state and attempts to establish a connection
    /// using the provided credentials. On success, the local publisher is added to the session
    /// and plugins are notified.
    ///
    /// - Important: Requires prior call to ``setup()``.
    /// - Warning: Calling while already connected has no effect.
    /// - SeeAlso: ``disconnect()``
    public func connect() {
        do {
            updateCallState(to: .connecting)
            try session.connect(with: credentials.token)
        } catch {
            _eventsPublisher.value = .error(error)
        }
    }

    /// Disconnects from the Vonage session and performs complete cleanup.
    ///
    /// Gracefully terminates the call, cleaning up subscribers, publisher, plugins,
    /// and session resources. Updates the call state to ``CallState/disconnected`` upon completion.
    ///
    /// - Throws: ``Error/callNotConnected`` if the call is not currently in ``CallState/connected``.
    /// - Important: Cancels Combine subscriptions and clears plugin assignments as part of teardown.
    public func disconnect() async throws {
        guard _callState.value == .connected else {
            _eventsPublisher.value = .error(CallError.callNotConnected)
            throw CallError.callNotConnected
        }
        _callState.value = .disconnecting

        do {
            await callStateManager.cleanUpParticipants()
            await notifyCallDidEndToPlugins()
            unassignPlugins()
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
            publisherCancellables.removeAll()
            stopCaptionCleanup()
            isNetworkStatsEnabled = false
            statsCollector.reset()
            try session.disconnect()
            publisher.cleanUp()
            session.cleanUp()
            updateCallState(to: .disconnected)
        } catch {
            _eventsPublisher.value = .error(error)
            publisher.cleanUp()
            session.cleanUp()
            updateCallState(to: .disconnected)
            throw error
        }
    }

    private func sessionDidFail(_ error: Swift.Error) {
        _eventsPublisher.send(.sessionFailure(error))
    }

    private func sessionDidDisconnect() {
        _eventsPublisher.send(.disconnected)
    }

    private func sessionDidBeginReconnecting() {
        _eventsPublisher.send(.didBeginReconnecting)
    }

    private func sessionDidReconnect() {
        _eventsPublisher.send(.didReconnect)
    }

    // MARK: Audio/Video toggles

    /// A Boolean value indicating whether both local audio and video publishing are disabled.
    ///
    /// Returns `true` if neither audio nor video is currently being published by the local participant.
    /// - Note: Does not reflect hold state; see ``isOnHold``.
    public var isMuted: Bool {
        !publisher.publishAudio && !publisher.publishVideo
    }

    /// Switches the local camera between front and back positions.
    ///
    /// Toggles the camera input source. If currently using the front camera,
    /// it switches to the back camera, and vice versa.
    /// - Note: Does not enable video if currently disabled.
    public func toggleLocalCamera() {
        publisher.cameraPosition = publisher.cameraPosition == .front ? .back : .front
    }

    /// Toggles the local video publishing state.
    ///
    /// Enables video publishing if it's currently disabled, or disables it if enabled.
    /// The updated state is emitted through ``statePublisher``.
    /// - SeeAlso: ``statePublisher``
    public func toggleLocalVideo() {
        publisher.publishVideo.toggle()
        updateMediaState()
    }

    /// Toggles the local audio publishing state.
    ///
    /// Enables audio publishing if it's currently disabled, or disables it if enabled.
    /// The updated state is emitted through ``statePublisher``.
    /// - SeeAlso: ``statePublisher``
    public func toggleLocalAudio() {
        publisher.publishAudio.toggle()
        updateMediaState()
    }

    private func updateMediaState() {
        _statePublisher.value = SessionState(
            isPublishingAudio: publisher.publishAudio,
            isPublishingVideo: publisher.publishVideo)
    }

    /// A Boolean value indicating whether the call is currently on hold.
    ///
    /// When on hold, local publishing and remote subscriptions are disabled to conserve bandwidth,
    /// but the session connection remains active.
    /// - SeeAlso: ``setOnHold(_:)``, ``muteLocalMedia(_:)``
    public var isOnHold: Bool { publisher.isOnHold }

    /// Sets the hold state of the call.
    ///
    /// - Parameter isOnHold: `true` to put the call on hold, `false` to resume.
    ///
    /// - Important: On hold, no media is sent or received, but the connection remains active.
    /// - SeeAlso: ``isOnHold``, ``muteLocalMedia(_:)``
    public func setOnHold(_ isOnHold: Bool) {
        Task { [weak self] in
            guard let self else { return }
            self.publisher.setOnHold(isOnHold)
            await self.callStateManager.setOnHold(isOnHold)
        }
    }

    /// Mutes or unmutes both local audio and video simultaneously.
    ///
    /// - Parameter isMuted: When `true`, disables both audio and video; when `false`, enables both.
    /// - Warning: Overrides individual audio/video toggles. Use ``toggleLocalAudio()`` or ``toggleLocalVideo()`` for independent control.
    public func muteLocalMedia(_ isMuted: Bool) {
        Task { [weak self] in
            guard let self else { return }
            self.publisher.publishAudio = !isMuted
            self.publisher.publishVideo = !isMuted
        }
    }

    // MARK: Signals

    private var callParams: [String: String] {
        [
            VonageCallParams.username.rawValue: publisher.participant.name,
            VonageCallParams.roomName.rawValue: credentials.roomName,
            VonageCallParams.callID.rawValue: id.uuidString,
            VonageCallParams.applicationId.rawValue: credentials.applicationId,
            VonageCallParams.sessionId.rawValue: credentials.sessionId,
            VonageCallParams.token.rawValue: credentials.token,
        ]
    }

    /// Assigns plugins to extend the call's functionality.
    ///
    /// Configures each plugin with necessary dependencies:
    /// - `VonageSignalEmitter`: Receives a signal channel
    /// - `VonagePluginCallHolder`: Receives a call reference
    /// Plugins are automatically started when the call connects and ended when it disconnects.
    ///
    /// - Parameter plugins: Array of plugins conforming to `VonagePlugin`.
    /// - Important: Assign plugins before ``connect()`` to ensure proper initialization.
    /// - SeeAlso: ``plugins``, `VonageSignalEmitter`, `VonagePluginCallHolder`, `VonageSignalHandler`
    public func assignPlugins(_ plugins: [any VonagePlugin]) {
        self.plugins = plugins

        plugins.forEach {
            if let channelHolder = $0 as? VonageSignalEmitter {
                channelHolder.channel = session
            }

            if let callHolder = $0 as? VonagePluginCallHolder {
                callHolder.call = self
            }
        }
    }

    private func unassignPlugins() {
        plugins.forEach {
            if let channelHolder = $0 as? VonageSignalEmitter {
                channelHolder.channel = nil
            }

            if let callHolder = $0 as? VonagePluginCallHolder {
                callHolder.call = nil
            }
        }

        plugins.removeAll()
    }

    private func notifyCallDidStartToPlugins() async {
        await withTaskGroup(of: (String, Result<Void, Swift.Error>).self) { group in
            for plugin in plugins {
                group.addTask {
                    do {
                        try await plugin.callDidStart(self.callParams)
                        return (plugin.pluginIdentifier, .success(()))
                    } catch {
                        return (plugin.pluginIdentifier, .failure(error))
                    }
                }
            }

            for await (identifier, result) in group {
                switch result {
                case .success:
                    print("✅ Plugin \(identifier) started successfully")
                case .failure(let error):
                    print("❌ Plugin \(identifier) failed to start: \(error)")
                    self._eventsPublisher.send(.error(error))
                }
            }
        }
    }

    private func notifyCallDidEndToPlugins() async {
        await withTaskGroup(of: (String, Result<Void, Swift.Error>).self) { group in
            for plugin in plugins {
                group.addTask {
                    do {
                        try await plugin.callDidEnd()
                        return (plugin.pluginIdentifier, .success(()))
                    } catch {
                        return (plugin.pluginIdentifier, .failure(error))
                    }
                }
            }

            for await (identifier, result) in group {
                switch result {
                case .success:
                    print("✅ Plugin \(identifier) ended successfully")
                case .failure(let error):
                    print("❌ Plugin \(identifier) failed to end: \(error)")
                    self._eventsPublisher.send(.error(error))
                }
            }
        }
    }

    private func handleSignal(_ signal: VonageSignal) {
        plugins.compactMap { $0 as? VonageSignalHandler }
            .forEach { $0.handleSignal(signal) }
    }

    // MARK: Apply Publisher Settings

    /// Applies new publisher settings to the active call by performing a republish cycle.
    ///
    /// Because Vonage SDK settings (resolution, frame rate, codec, audio bitrate,
    /// audio fallback) are immutable on a live ``OTPublisher``, this method:
    ///
    /// 1. Captures the current runtime state (audio/video mute, camera position,
    ///    video transformers, stats delegate, captions).
    /// 2. Unpublishes and cleans up the current publisher.
    /// 3. Recreates the publisher with the new SDK settings via ``PublisherRepository``.
    /// 4. Re-publishes the new publisher to the session.
    /// 5. Restores all captured runtime state.
    ///
    /// - Parameter advancedSettings: The desired publisher configuration. Only the SDK-level
    ///   fields (resolution, frame rate, codec, audio bitrate, audio fallback) are
    ///   used; audio/video publishing, camera position, and transformers are preserved.
    /// - Throws: If unpublish, publisher recreation, or re-publish fails.
    @MainActor
    public func applyPublisherAdvancedSettings(_ advancedSettings: PublisherAdvancedSettings) async throws {
        guard _callState.value == .connected else { return }

        // 1. Capture current runtime state
        let wasPublishingAudio = publisher.publishAudio
        let wasPublishingVideo = publisher.publishVideo
        let cameraPos = publisher.cameraPosition
        let currentTransformers = publisher.videoTransformers
        let wasStatsEnabled = isNetworkStatsEnabled
        let wasCaptionsEnabled = areCaptionsEnabled
        let publisherName = publisher.participant.name
        let publisherScaleBehavior = publisher.scaleBehavior
        let currentAudioTransformers = publisher.audioTransformers

        // 2. Clean up publisher captions subscriber if it exists
        if let captionsSub = publisherCaptions {
            try? session.unsubscribe(subscriber: captionsSub)
            publisherCaptions = nil
        }

        // 3. Unpublish and clean up the current publisher
        // Cancel publisher observation BEFORE cleanUp() — cleanUp() fires $participant
        // with EmptyView, and if the sink is still active it enqueues an async Task that
        // would later overwrite publisherParticipant with an empty-view participant,
        // blanking the local video tile after the new publisher is already set up.
        publisherCancellables.removeAll()
        try session.unpublish(publisher: publisher)
        publisher.cleanUp()

        // Yield so the run loop can process the unpublish event before OTPublisher init.
        await Task.yield()

        // 4. Build merged settings: new SDK fields + preserved runtime state
        let mergedSettings = PublisherSettings(
            username: publisherName,
            publishAudio: wasPublishingAudio,
            publishVideo: wasPublishingVideo,
            scaleBehavior: publisherScaleBehavior,
            advancedSettings: .init(
                videoResolution: advancedSettings.videoResolution,
                videoFrameRate: advancedSettings.videoFrameRate,
                preferredVideoCodecs: advancedSettings.preferredVideoCodecs,
                maxAudioBitrate: advancedSettings.maxAudioBitrate,
                maxVideoBitrate: advancedSettings.maxVideoBitrate,
                publisherAudioFallbackEnabled: advancedSettings.publisherAudioFallbackEnabled,
                subscriberAudioFallbackEnabled: advancedSettings.subscriberAudioFallbackEnabled
            )
        )

        // 5. Recreate the publisher off the main thread to avoid blocking
        try publisherRepository.recreatePublisher(mergedSettings)

        guard let newPublisher = try publisherRepository.getPublisher() as? VonagePublisher else {
            return
        }

        // 6. Replace the publisher reference and re-publish
        self.publisher = newPublisher
        publishToSession()

        // 7. Restore camera position
        newPublisher.cameraPosition = cameraPos

        // 8. Restore video transformers
        if !currentTransformers.isEmpty {
            newPublisher.setVideoTransformers(currentTransformers)
        }

        // 9. Restore audio transformers
        if !currentAudioTransformers.isEmpty {
            newPublisher.setAudioTransformers(currentAudioTransformers)
        }

        // 10. Restore network stats delegate
        if wasStatsEnabled {
            newPublisher.otPublisher.networkStatsDelegate = statsCollector
            statsCollector.requestRtcStats(from: newPublisher.otPublisher)
        }

        // 11. Restore captions
        if wasCaptionsEnabled {
            newPublisher.enableCaptions()
            if let stream = newPublisher.stream {
                subscribeToPublisherCaptions(stream)
            }
        }

        // 12. Update media state
        updateMediaState()

        // 13. Update participants state
        let state = await callStateManager.getCurrentState()
        await updateParticipantsState(state)
    }

    // MARK: Network Stats

    /// Starts collecting network statistics from the SDK.
    ///
    /// Sets the `networkStatsDelegate` on the publisher and all current subscribers.
    /// New subscribers added after this call will also have their delegate set automatically.
    public func enableNetworkStats() {
        guard !isNetworkStatsEnabled else { return }
        isNetworkStatsEnabled = true

        publisher.otPublisher.networkStatsDelegate = statsCollector
        statsCollector.requestRtcStats(from: publisher.otPublisher)

        Task { [weak self] in
            guard let self else { return }
            let subscribers = await self.callStateManager.getAllSubscribers()
            for subscriber in subscribers {
                subscriber.otSubscriber.networkStatsDelegate = self.statsCollector
                self.statsCollector.requestRtcStats(from: subscriber.otSubscriber)
            }
        }
    }

    /// Stops collecting network statistics and clears cached data.
    ///
    /// Removes the `networkStatsDelegate` from the publisher and all subscribers,
    /// and resets the collector to emit ``NetworkMediaStats/empty``.
    public func disableNetworkStats() {
        guard isNetworkStatsEnabled else { return }
        isNetworkStatsEnabled = false

        publisher.otPublisher.networkStatsDelegate = nil
        publisher.otPublisher.rtcStatsReportDelegate = nil
        statsCollector.reset()

        Task { [weak self] in
            guard let self else { return }
            let subscribers = await self.callStateManager.getAllSubscribers()
            for subscriber in subscribers {
                subscriber.otSubscriber.networkStatsDelegate = nil
                subscriber.otSubscriber.rtcStatsReportDelegate = nil
            }
        }
    }

    // MARK: Captions

    public var areCaptionsEnabled: Bool { _captionsEnabled.value }

    @MainActor
    public func enableCaptions() async {
        await callStateManager.enableCaptions()

        if let stream = publisher.stream, publisherCaptions == nil {
            subscribeToPublisherCaptions(stream)
        }
        publisher.enableCaptions()
        _captionsEnabled.value = true

        startCaptionCleanup()
    }

    public func disableCaptions() async {
        await callStateManager.disableCaptions()
        publisher.disableCaptions()
        _captionsEnabled.value = false
        stopCaptionCleanup()
    }

    private func subscribeToPublisherCaptions(_ stream: OTStream) {
        do {
            let vonageSubscriber = try subscriberFactory.makeSubscriber(stream)
            vonageSubscriber.onError = { [weak self] in
                self?.removeSubscriber(stream)
            }

            try session.subscribe(subscriber: vonageSubscriber)

            vonageSubscriber.onConnected = { [weak vonageSubscriber] in
                vonageSubscriber?.enableCaptions()
                vonageSubscriber?.enableAudioSubscription(false)
            }

            vonageSubscriber.onCaption = { [weak self] caption in
                self?.appendCaption(caption, isMe: true)
            }

            publisherCaptions = vonageSubscriber
        } catch {
            _eventsPublisher.send(.error(error))
        }
    }

    private func startCaptionCleanup() {
        stopCaptionCleanup()
        captionCleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.cleanupOldCaptions()
        }
    }

    private func stopCaptionCleanup() {
        captionCleanupTimer?.invalidate()
        captionCleanupTimer = nil
    }

    private func cleanupOldCaptions() {
        let now = Date()
        let maxCaptionAge: TimeInterval = 5.0

        let value = _captionsPublisher.value
        let filtered = value.filter { now.timeIntervalSince($0.timestamp) < maxCaptionAge }

        if filtered.count != value.count {
            _captionsPublisher.value = filtered
        }
    }

    private func appendCaption(_ caption: VonageCaption, isMe: Bool = false) {
        /// Before appending, any existing caption from the **same speaker** is removed.
        var value = _captionsPublisher.value.filter { $0.id != caption.id ?? "" }
        value.append(
            .init(id: caption.id ?? UUID().uuidString, speakerName: caption.name ?? "", text: caption.text, isMe: isMe))

        if value.count > 5 {
            value = Array(value.suffix(5))
        }

        _captionsPublisher.value = value
    }
}
