//
//  Created by Vonage on 8/6/26.
//

import Combine
import Foundation
import VERADomain
import VERAVonage

public final class E2ECallFacade: CallFacade {
    private var cancellables = Set<AnyCancellable>()
    private let pluginNotifier: E2ECallPluginNotifier

    private let networkStatsSubject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    public lazy var networkStatsPublisher = networkStatsSubject.eraseToAnyPublisher()

    private let eventsSubject = CurrentValueSubject<SessionEvent, Never>(.idle)
    public lazy var eventsPublisher = eventsSubject.eraseToAnyPublisher()

    private let participantsSubject = CurrentValueSubject<ParticipantsState, Never>(.empty)
    public lazy var participantsPublisher = participantsSubject.eraseToAnyPublisher()

    private let stateSubject: CurrentValueSubject<SessionState, Never>
    public lazy var statePublisher = stateSubject.eraseToAnyPublisher()

    private let callStateSubject = CurrentValueSubject<CallState, Never>(.idle)
    public lazy var callState = callStateSubject.eraseToAnyPublisher()

    private let archivingStateSubject = CurrentValueSubject<ArchivingState, Never>(.idle)
    public lazy var archivingState = archivingStateSubject.eraseToAnyPublisher()

    private let captionsSubject = CurrentValueSubject<[CaptionItem], Never>([])
    public lazy var captionsPublisher = captionsSubject.eraseToAnyPublisher()

    public private(set) var isMuted = false
    public private(set) var isOnHold = false
    public private(set) var areCaptionsEnabled = false

    public init(
        publisherSettings: PublisherSettings = .init(),
        plugins: [any VonagePlugin] = [],
        credentials: RoomCredentials? = nil
    ) {
        pluginNotifier = E2ECallPluginNotifier(
            plugins: plugins,
            callParams: E2ECallParamsBuilder.callParams(from: credentials))
        stateSubject = CurrentValueSubject<SessionState, Never>(
            .init(
                isPublishingAudio: publisherSettings.publishAudio,
                isPublishingVideo: publisherSettings.publishVideo))
        pluginNotifier.assign(call: self)
        observeArchivingEvents()
    }

    public func connect() {
        callStateSubject.send(.connecting)
        callStateSubject.send(.connected)
        eventsSubject.send(.connected)
        Task { await pluginNotifier.notifyCallDidStart() }
    }

    public func disconnect() async throws {
        callStateSubject.send(.disconnecting)
        await pluginNotifier.notifyCallDidEnd()
        callStateSubject.send(.disconnected)
        eventsSubject.send(.disconnected)
        pluginNotifier.unassign()
    }

    public func toggleLocalVideo() {
        let current = stateSubject.value
        stateSubject.send(
            .init(
                isPublishingAudio: current.isPublishingAudio,
                isPublishingVideo: !current.isPublishingVideo))
    }

    public func toggleLocalCamera() {}

    public func toggleLocalAudio() {
        let current = stateSubject.value
        stateSubject.send(
            .init(
                isPublishingAudio: !current.isPublishingAudio,
                isPublishingVideo: current.isPublishingVideo))
    }

    public func muteLocalMedia(_ isMuted: Bool) {
        self.isMuted = isMuted
        stateSubject.send(
            .init(
                isPublishingAudio: !isMuted,
                isPublishingVideo: !isMuted))
    }

    public func setOnHold(_ isOnHold: Bool) {
        self.isOnHold = isOnHold
    }

    public func enableCaptions() async {
        areCaptionsEnabled = true
        captionsSubject.send(E2ECallCaptionsFactory.enabledCaptions())
    }

    public func disableCaptions() async {
        areCaptionsEnabled = false
        captionsSubject.send([])
    }

    public func enableNetworkStats() {}

    public func disableNetworkStats() {
        networkStatsSubject.send(.empty)
    }

    public func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws {}

    private func observeArchivingEvents() {
        NotificationCenter.default.publisher(for: E2EArchivingEvents.didStart)
            .sink { [weak self] notification in
                guard let archiveId = notification.object as? String else { return }
                self?.archivingStateSubject.send(.archiving(archiveId))
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: E2EArchivingEvents.didStop)
            .sink { [weak self] _ in
                self?.archivingStateSubject.send(.idle)
            }
            .store(in: &cancellables)
    }
}
