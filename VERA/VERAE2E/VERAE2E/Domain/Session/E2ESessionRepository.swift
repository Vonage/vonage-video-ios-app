//
//  Created by Vonage on 7/6/26.
//

import VERADomain
import VERAVonage

public final class E2ESessionRepository: SessionRepository {
    public private(set) var currentCall: (any CallFacade)?
    private let roomCredentialsRepository: any RoomCredentialsRepository
    private let sessionKeyWriter: any SessionKeyWriter
    private let publisherSettings: PublisherSettings
    private let plugins: [any VonagePlugin]

    public init(
        roomCredentialsRepository: any RoomCredentialsRepository,
        sessionKeyWriter: any SessionKeyWriter,
        publisherSettings: PublisherSettings = .init(),
        plugins: [any VonagePlugin] = []
    ) {
        self.roomCredentialsRepository = roomCredentialsRepository
        self.sessionKeyWriter = sessionKeyWriter
        self.publisherSettings = publisherSettings
        self.plugins = plugins
    }

    public func createSession(for roomName: RoomName) async throws -> any CallFacade {
        if let currentCall {
            return currentCall
        }

        let response = try await roomCredentialsRepository.getRoomCredentials(.init(roomName: roomName))
        let credentials = response.asRoomCredentials(with: roomName)
        sessionKeyWriter.setSessionKey(credentials.sessionKey)

        let call = E2ECallFacade(
            publisherSettings: publisherSettings,
            plugins: plugins,
            credentials: credentials)
        currentCall = call
        return call
    }

    public func clearSession() {
        currentCall = nil
    }
}
