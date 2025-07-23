//
//  Created by Vonage on 23/7/25.
//

import Foundation

final class ConnectToRoomUseCase {

    private let getRoomCredentialsUseCase: GetRoomCredentialsUseCase
    private let sessionRepository: SessionRepository

    init(
        getRoomCredentialsUseCase: GetRoomCredentialsUseCase,
        sessionRepository: SessionRepository
    ) {
        self.getRoomCredentialsUseCase = getRoomCredentialsUseCase
        self.sessionRepository = sessionRepository
    }

    @BackgroundActor
    func invoke(roomName: RoomName) async throws {
        let result = try await getRoomCredentialsUseCase.getRoomCredentials(.init(roomName: roomName))
        sessionRepository.createSession(result.roomCredentials)
    }
}

extension RoomCredentialsResponse {
    var roomCredentials: RoomCredentials {
        .init(
            sessionId: sessionId,
            token: token,
            apiKey: apiKey,
            captionsId: captionsId)
    }
}
