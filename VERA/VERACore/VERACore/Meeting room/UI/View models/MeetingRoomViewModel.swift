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
    public let roomURL: URL?
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let participants: [Participant]
    public let layout: MeetingRoomLayout
    public let activeSpeakerId: String?

    public var participantsCount: Int {
        participants.count
    }

    public init(
        roomName: RoomName,
        roomURL: URL?,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participants: [Participant],
        layout: MeetingRoomLayout,
        activeSpeakerId: String?
    ) {
        self.roomName = roomName
        self.roomURL = roomURL
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participants = participants
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
    }

    public static let `default` = MeetingRoomState(
        roomName: "",
        roomURL: nil,
        isMicEnabled: false,
        isCameraEnabled: false,
        participants: [],
        layout: .activeSpeaker,
        activeSpeakerId: nil)
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

    public weak var currentCall: CallFacade?

    public let roomName: RoomName
    public let baseURL: URL
    private var initialised: Bool = false

    public init(
        roomName: RoomName,
        baseURL: URL,
        connectToRoomUseCase: ConnectToRoomUseCase,
        disconnectRoomUseCase: DisconnectRoomUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository
    ) {
        self.roomName = roomName
        self.baseURL = baseURL
        self.connectToRoomUseCase = connectToRoomUseCase
        self.disconnectRoomUseCase = disconnectRoomUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
    }

    public func loadUI() {
        guard !initialised else { return }
        initialised = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            state = .loading

            do {
                let call = try await connectToRoomUseCase(roomName: roomName)
                observeSessionState(call.participantsPublisher)

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

    func observeSessionState(_ participantsPublisher: AnyPublisher<ParticipantsState, Never>) {
        Publishers.CombineLatest3(
            participantsPublisher
                .removeDuplicates(),
            sessionStatePublisher,
            layoutPublisher
        )
        .map { [weak self] participantsState, sessionState, layout in
            guard let self else { return MeetingRoomState.default }

            var sortedPaticipants = participantsState.participants
            if layout == .activeSpeaker {
                sortedPaticipants = sortedPaticipants.sortedByDisplayPriority(
                    activeSpeakerId: participantsState.activeParticipantId)
                if let localParticipant = participantsState.localParticipant {
                    if sortedPaticipants.isEmpty {
                        sortedPaticipants.append(localParticipant)
                    } else {
                        sortedPaticipants.insert(localParticipant, at: 1)
                    }
                }
            } else {
                sortedPaticipants = sortedPaticipants.sortedByCreationDate()
                if let localParticipant = participantsState.localParticipant {
                    if sortedPaticipants.isEmpty {
                        sortedPaticipants.append(localParticipant)
                    } else {
                        sortedPaticipants.insert(localParticipant, at: 0)
                    }
                }
            }

            return MeetingRoomState(
                roomName: self.roomName,
                roomURL: baseURL.appendingPathComponent(roomName),
                isMicEnabled: sessionState.isPublishingAudio,
                isCameraEnabled: sessionState.isPublishingVideo,
                participants: sortedPaticipants,
                layout: layout,
                activeSpeakerId: participantsState.activeParticipantId)
        }
        .removeDuplicates()
        .sink { [weak self] newState in
            Task { @MainActor in
                self?.state = .content(newState)
            }
        }
        .store(in: &cancellables)
    }

    public func onToggleMic() {
        currentCall?.toggleLocalAudio()
    }

    public func onToggleCamera() {
        currentCall?.toggleLocalVideo()
    }

    public func onCameraSwitch() {
        currentCall?.toggleLocalCamera()
    }

    public func onToggleLayout() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let newLayout: MeetingRoomLayout =
                switch layoutPublisher.value {
                case .grid: .activeSpeaker
                case .activeSpeaker: .grid
                }
            layoutPublisher.value = newLayout
        }
    }

    public func endCall() {
        Task { [weak self] in
            do {
                try await self?.disconnectRoomUseCase()
            } catch {
                Task { @MainActor [weak self] in
                    self?.error = AlertItem.genericError(error.localizedDescription)
                }
            }
        }
    }
}
