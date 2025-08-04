//
//  Created by Vonage on 30/7/25.
//

import Foundation

public final class GoodByeViewModel {
    private let roomName: RoomName
    private let joinRoomUseCase: JoinRoomUseCase
    private let userRepository: UserRepository

    init(
        roomName: RoomName,
        joinRoomUseCase: JoinRoomUseCase,
        userRepository: UserRepository
    ) {
        self.roomName = roomName
        self.joinRoomUseCase = joinRoomUseCase
        self.userRepository = userRepository
    }

    @BackgroundActor
    public func joinRoom() async {
        do {
            let username = try await userRepository.get()?.name ?? ""
            let request = JoinRoomRequest(roomName: roomName, userName: username)
            try await joinRoomUseCase(request)
        } catch {
            print(error.localizedDescription)
        }
    }
}
