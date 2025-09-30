//
//  Created by Vonage on 23/7/25.
//

import Foundation

public final class ConnectToRoomUseCase {

    private let sessionRepository: SessionRepository
    private let roomCredentialsRepository: RoomCredentialsRepository

    public init(
        sessionRepository: SessionRepository,
        roomCredentialsRepository: RoomCredentialsRepository
    ) {
        self.sessionRepository = sessionRepository
        self.roomCredentialsRepository = roomCredentialsRepository
    }

    public func callAsFunction(roomName: RoomName) async throws -> CallFacade {
        let result = try await roomCredentialsRepository.getRoomCredentials(.init(roomName: roomName))
        return await getConnectedCall(result.roomCredentials)
    }

    @MainActor
    private func getConnectedCall(_ credentials: RoomCredentials) async -> CallFacade {
        let call = await sessionRepository.createSession(credentials)
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
