//
//  Created by Vonage on 06/03/2026.
//

import Combine
import VERADomain

final class MockCallFacade: CallFacade, @unchecked Sendable {

    let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(.empty)
    lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    let _statePublisher = CurrentValueSubject<SessionState, Never>(.initial)
    lazy var statePublisher: AnyPublisher<SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    let _callState = CurrentValueSubject<CallState, Never>(.idle)
    lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    let _archivingState = CurrentValueSubject<ArchivingState, Never>(.idle)
    lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    let _captionsPublisher = CurrentValueSubject<[CaptionItem], Never>([])
    lazy var captionsPublisher: AnyPublisher<[CaptionItem], Never> = _captionsPublisher.eraseToAnyPublisher()

    let _networkStatsPublisher = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    lazy var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> =
        _networkStatsPublisher.eraseToAnyPublisher()

    var isMuted: Bool = false
    var isOnHold: Bool = false
    var areCaptionsEnabled = false

    var enableNetworkStatsCallCount = 0
    var disableNetworkStatsCallCount = 0
    var applyPublisherAdvancedSettingsCallCount = 0
    var lastAppliedSettings: PublisherAdvancedSettings?

    func connect() {}
    func disconnect() async throws {}
    func toggleLocalVideo() {}
    func toggleLocalAudio() {}
    func toggleLocalCamera() {}
    func muteLocalMedia(_ isMuted: Bool) { self.isMuted = isMuted }
    func setOnHold(_ isOnHold: Bool) { self.isOnHold = isOnHold }
    func enableCaptions() async { areCaptionsEnabled = true }
    func disableCaptions() async { areCaptionsEnabled = false }

    func enableNetworkStats() {
        enableNetworkStatsCallCount += 1
    }

    func disableNetworkStats() {
        disableNetworkStatsCallCount += 1
    }

    func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws {
        applyPublisherAdvancedSettingsCallCount += 1
        lastAppliedSettings = settings
    }
}
