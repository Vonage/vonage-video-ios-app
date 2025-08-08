//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation

public typealias MeetingRoomError = String

public enum MeetingRoomViewState: Equatable {
    case loading
    case content(MeetingRoomState)
}

public enum MeetingRoomLayout {
    case activeSpeaker, grid
}

public struct MeetingRoomState: Equatable {

    public let roomName: RoomName
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let participants: [Participant]
    public let layout: MeetingRoomLayout

    public var participantsCount: Int {
        participants.count
    }

    public init(
        roomName: RoomName,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participants: [Participant],
        layout: MeetingRoomLayout
    ) {
        self.roomName = roomName
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participants = participants
        self.layout = layout
    }

    public static let `default` = MeetingRoomState(
        roomName: "",
        isMicEnabled: false,
        isCameraEnabled: false,
        participants: [],
        layout: .activeSpeaker)
}

public final class MeetingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let disconnectRoomUseCase: DisconnectRoomUseCase

    @MainActor @Published public var state: MeetingRoomViewState = .loading
    @MainActor @Published public var error: AlertItem? = nil
    private let layoutPublisher = CurrentValueSubject<MeetingRoomLayout, Never>(MeetingRoomLayout.activeSpeaker)
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(SessionState.default)
    private let participantsPublisher = CurrentValueSubject<[Participant], Never>([])
    private let activeSpeakerTracker = ActiveSpeakerTracker()
    
    public weak var currentCall: CallFacade?

    public let roomName: RoomName

    public init(
        roomName: RoomName,
        connectToRoomUseCase: ConnectToRoomUseCase,
        disconnectRoomUseCase: DisconnectRoomUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository
    ) {
        self.roomName = roomName
        self.connectToRoomUseCase = connectToRoomUseCase
        self.disconnectRoomUseCase = disconnectRoomUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
    }

    public func loadUI() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            state = .loading
            observeSessionState()

            do {
                let call = try await connectToRoomUseCase(roomName: roomName)
                call.participantsPublisher
                    .removeDuplicates()
                    .sink { [weak self] participants in
                        self?.activeSpeakerTracker.calculateActiveSpeaker(from: participants)
                        self?.participantsPublisher.send(participants)
                    }
                    .store(in: &cancellables)

                call.statePublisher
                    .sink { [weak self] state in
                        self?.sessionStatePublisher.send(state)
                    }
                    .store(in: &cancellables)

                self.currentCall = call
            } catch {
                Task { @MainActor [weak self] in
                    self?.error = AlertItem.genericError(error.localizedDescription)
                }
            }
        }
    }

    func observeSessionState() {
        Publishers.CombineLatest4(
            participantsPublisher,
            sessionStatePublisher,
            layoutPublisher,
            activeSpeakerTracker.$activeSpeaker
        )
        .map { [weak self] participants, sessionState, layout, activeSpeaker in
            guard let self else { return MeetingRoomState.default }
            var sortedPaticipants = participants
                
            if layout == .activeSpeaker {
                sortedPaticipants = participants.sortedByDisplayPriority(
                    activeSpeakerId: activeSpeaker.participantId)
            }
                
            return MeetingRoomState(
                roomName: self.roomName,
                isMicEnabled: sessionState.isPublishingAudio,
                isCameraEnabled: sessionState.isPublishingVideo,
                participants: sortedPaticipants,
                layout: layout)
        }
        .removeDuplicates()
        .receive(on: DispatchQueue.main)
        .sink { [weak self] newState in
            Task { @MainActor in
                self?.state = .content(newState)
            }
        }
        .store(in: &cancellables)
    }

    public func onToggleMic() {
        Task { [weak self] in
            self?.currentCall?.toggleLocalAudio()
        }
    }

    public func onToggleCamera() {
        Task { [weak self] in
            self?.currentCall?.toggleLocalVideo()
        }
    }

    public func onCameraSwitch() {
        Task { [weak self] in
            self?.currentCall?.toggleLocalCamera()
        }
    }

    public func endCall() {
        disconnectRoomUseCase()
    }
}
