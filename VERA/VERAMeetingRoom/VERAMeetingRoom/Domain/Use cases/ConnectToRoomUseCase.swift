//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERADomain

public protocol ConnectToRoomUseCase {
    func callAsFunction(roomName: RoomName) async throws -> CallFacade
}

public final class DefaultConnectToRoomUseCase: ConnectToRoomUseCase {

    private let sessionRepository: SessionRepository

    public init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    public func callAsFunction(roomName: RoomName) async throws -> CallFacade {
        let call = try await sessionRepository.createSession(for: roomName)
        try await call.connect()
        return call
    }
}
