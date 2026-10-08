//
//  Created by Vonage on 27/9/26.
//

import Foundation
import VERADomain

public final class VonageSessionProvider<Factory: SessionFactory>: SessionProvider
where Factory.Session == VonageSession {

    private let sessionFactory: Factory
    private let roomCredentialsRepository: RoomCredentialsRepository
    private let sessionKeyWriter: SessionKeyWriter

    public init(
        sessionFactory: Factory,
        roomCredentialsRepository: RoomCredentialsRepository,
        sessionKeyWriter: SessionKeyWriter
    ) {
        self.sessionFactory = sessionFactory
        self.roomCredentialsRepository = roomCredentialsRepository
        self.sessionKeyWriter = sessionKeyWriter
    }

    public func makeSession(for roomName: RoomName) async throws -> VonageSession {
        let response = try await roomCredentialsRepository.getRoomCredentials(.init(roomName: roomName))
        let credentials = response.asRoomCredentials(with: roomName)
        let session = try sessionFactory.make(credentials)
        sessionKeyWriter.setSessionKey(credentials.sessionKey)
        return session
    }
}
