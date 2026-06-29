//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERADomain

/// Use case for connecting to a room via a JWT session key, bypassing the `createSession` step.
///
/// `ConnectWithSessionKeyUseCase` encapsulates the workflow to resolve credentials from a
/// session key (JWT) and initiate the call connection, joining directly without calling the
/// backend `createSession` endpoint.
///
/// - SeeAlso: ``DefaultConnectWithSessionKeyUseCase``, ``SessionRepository``, ``RoomCredentialsRepository``, ``CallFacade``
public protocol ConnectWithSessionKeyUseCase {
    /// Connects to a room using a session key (JWT) and returns a configured, connected call façade.
    ///
    /// This skips the `createSession` step and joins directly using the provided session key.
    /// - Parameter sessionKey: The JWT session key from a deep link.
    /// - Returns: A connected ``CallFacade`` ready for use.
    /// - Throws: Errors resolving credentials or creating the session.
    func callAsFunction(sessionKey: String) async throws -> CallFacade
}

/// Default implementation of ``ConnectWithSessionKeyUseCase``.
///
/// `DefaultConnectWithSessionKeyUseCase` fetches credentials via the session key,
/// then triggers the connection on the resulting call façade.
public final class DefaultConnectWithSessionKeyUseCase: ConnectWithSessionKeyUseCase {

    private let sessionRepository: SessionRepository
    private let roomCredentialsRepository: RoomCredentialsRepository
    private let sessionKeyWriter: SessionKeyWriter

    /// Creates a new use case with required repositories.
    ///
    /// - Parameters:
    ///   - sessionRepository: Repository responsible for creating call sessions.
    ///   - roomCredentialsRepository: Repository that fetches room credentials from backend.
    ///   - sessionKeyWriter: Writer populated with the session key JWT after credentials are fetched.
    public init(
        sessionRepository: SessionRepository,
        roomCredentialsRepository: RoomCredentialsRepository,
        sessionKeyWriter: SessionKeyWriter
    ) {
        self.sessionRepository = sessionRepository
        self.roomCredentialsRepository = roomCredentialsRepository
        self.sessionKeyWriter = sessionKeyWriter
    }

    /// Connects to a room using a session key (JWT), skipping `createSession`.
    ///
    /// Extracts the room name from the JWT payload for display purposes,
    /// then joins the session directly using `joinSession`.
    ///
    /// - Parameter sessionKey: The JWT session key from a deep link.
    /// - Returns: A connected ``CallFacade`` ready for interaction.
    /// - Throws: Errors from credentials fetching or session creation.
    public func callAsFunction(sessionKey: String) async throws -> CallFacade {
        let result = try await roomCredentialsRepository.getCredentialsFromSessionKey(
            .init(sessionKey: sessionKey))
        let roomName = SessionKeyParser.extractRoomName(from: sessionKey) ?? "meeting"
        let credentials = result.asRoomCredentials(with: roomName)
        return try await getConnectedCall(credentials)
    }

    @MainActor
    private func getConnectedCall(_ credentials: RoomCredentials) async throws -> CallFacade {
        let call = try await sessionRepository.createSession(credentials)
        sessionKeyWriter.setSessionKey(credentials.sessionKey)
        call.connect()
        return call
    }
}
