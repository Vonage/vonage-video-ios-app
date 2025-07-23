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

    private let connectToRoomUseCase: ConnectToRoomUseCase
    private let currentCallParticipantsRepository: CurrentCallParticipantsRepository

    @MainActor @Published public var state: MeetingRoomViewState = .content(MeetingRoomState.default)
    @Published public var participants: [Participant] = []

    let roomName: RoomName

    init(
        roomName: RoomName,
        connectToRoomUseCase: ConnectToRoomUseCase,
        currentCallParticipantsRepository: CurrentCallParticipantsRepository
    ) {
        self.roomName = roomName
        self.connectToRoomUseCase = connectToRoomUseCase
        self.currentCallParticipantsRepository = currentCallParticipantsRepository
    }

    @MainActor
    func loadUI() async {
        state = .loading

        do {
            try await connectToRoomUseCase.invoke(roomName: roomName)

            state = .content(.default)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func onToggleMic() {
        //call?.togglePublisherAudio()
    }

    func onToggleCamera() {
        //call?.togglePublisherVideo()
    }

    func endCall() {
        //call?.endSession()
    }

    func onPause() {
        //call?.pauseSession()
    }

    func onResume() {
        //call?.resumeSession()
    }
}
