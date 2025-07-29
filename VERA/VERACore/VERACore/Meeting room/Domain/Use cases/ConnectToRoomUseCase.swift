//
//  Created by Vonage on 23/7/25.
//

import Foundation

public final class ConnectToRoomUseCase {

    private let getRoomCredentialsUseCase: GetRoomCredentialsUseCase
    private let sessionRepository: SessionRepository

    public init(
        getRoomCredentialsUseCase: GetRoomCredentialsUseCase,
        sessionRepository: SessionRepository
    ) {
        self.getRoomCredentialsUseCase = getRoomCredentialsUseCase
        self.sessionRepository = sessionRepository
    }

    @BackgroundActor
    public func callAsFunction(roomName: RoomName) async throws -> CallFacade {
        let result = try await getRoomCredentialsUseCase.getRoomCredentials(.init(roomName: roomName))
        let call = await sessionRepository.createSession(result.roomCredentials)
        call.connect()
        return call
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
