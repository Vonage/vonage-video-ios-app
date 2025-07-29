//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation

public typealias MeetingRoomError = String

public enum MeetingRoomViewState: Equatable {
    case loading
    case error(MeetingRoomError)
    case content(MeetingRoomState)
}

public struct MeetingRoomState: Equatable {

    let isMicEnabled: Bool
    let isCameraEnabled: Bool
    let participants: [Participant]

    var participantsCount: Int {
        participants.count
    }

    init(isMicEnabled: Bool, isCameraEnabled: Bool, participants: [Participant]) {
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participants = participants
    }

    public static let `default` = MeetingRoomState(
        isMicEnabled: false,
        isCameraEnabled: false,
        participants: [])
}

public final class MeetingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository
    private let disconnectRoomUseCase: DisconnectRoomUseCase

    @MainActor @Published public var state: MeetingRoomViewState = .content(MeetingRoomState.default)
    private let sessionStatePublisher = CurrentValueSubject<SessionState, Never>(SessionState.default)
    private let participantsPublisher = CurrentValueSubject<[Participant], Never>([])

    weak var currentCall: CallFacade?

    let roomName: RoomName

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

        Task { [weak self] in
            await self?.loadUI()
        }
    }

    @MainActor
    public func loadUI() async {
        state = .loading
        observeSessionState()

        do {
            let call = try await connectToRoomUseCase(roomName: roomName)
            call.participantsPublisher
                .sink { [weak self] participants in
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
            state = .error(error.localizedDescription)
        }
    }

    func observeSessionState() {
        Publishers.CombineLatest(participantsPublisher, sessionStatePublisher)
            .map { participants, sessionState in
                MeetingRoomState(
                    isMicEnabled: sessionState.isPublishingAudio,
                    isCameraEnabled: sessionState.isPublishingVideo,
                    participants: participants
                )
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

    public func endCall() {
        disconnectRoomUseCase()
    }
}
