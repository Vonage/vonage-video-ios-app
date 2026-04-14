//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERADomain

/// Use case for connecting to a room and returning a running call façade.
///
/// `ConnectToRoomUseCase` encapsulates the workflow to resolve credentials,
/// create a session, and initiate the call connection. It exposes the operation
/// via `callAsFunction(roomName:)` to enable succinct usage in async contexts.
///
/// - SeeAlso: ``DefaultConnectToRoomUseCase``, ``SessionRepository``, ``RoomCredentialsRepository``, ``CallFacade``
public protocol ConnectToRoomUseCase {
    /// Connects to the given room and returns a configured, connected call façade.
    ///
    /// - Parameter roomName: The room to join.
    /// - Returns: A connected ``CallFacade`` ready for use.
    /// - Throws: Errors resolving credentials or creating the session.
    func callAsFunction(roomName: RoomName) async throws -> CallFacade
}

/// Default implementation of ``ConnectToRoomUseCase``.
///
/// `DefaultConnectToRoomUseCase` orchestrates credentials fetching and session creation,
/// then triggers the connection on the resulting call façade.
///
/// ## Overview
///
/// Responsibilities:
/// - Fetch room credentials via ``RoomCredentialsRepository``
/// - Create a call via ``SessionRepository``
/// - Initiate the call connection
public final class DefaultConnectToRoomUseCase: ConnectToRoomUseCase {

    private let sessionRepository: SessionRepository
    private let roomCredentialsRepository: RoomCredentialsRepository

    /// Creates a new use case with required repositories.
    ///
    /// - Parameters:
    ///   - sessionRepository: Repository responsible for creating call sessions.
    ///   - roomCredentialsRepository: Repository that fetches room credentials from backend.
    public init(
        sessionRepository: SessionRepository,
        roomCredentialsRepository: RoomCredentialsRepository
    ) {
        self.sessionRepository = sessionRepository
        self.roomCredentialsRepository = roomCredentialsRepository
    }

    /// Connects to the given room and returns an active call façade.
    ///
    /// Resolves the room credentials, converts them to domain ``RoomCredentials``,
    /// creates a session via the repository, and triggers `connect()` on the call.
    ///
    /// - Parameter roomName: The target room name to connect to.
    /// - Returns: A connected ``CallFacade`` ready for interaction.
    /// - Throws: Errors from credentials fetching or session creation.
    public func callAsFunction(roomName: RoomName) async throws -> CallFacade {
        let result = try await roomCredentialsRepository.getRoomCredentials(.init(roomName: roomName))
        return try await getConnectedCall(result.asRoomCredentials(with: roomName))
    }

    /// Creates a call from credentials and connects it.
    ///
    /// - Parameter credentials: Domain-level room credentials.
    /// - Returns: A connected ``CallFacade``.
    /// - Throws: Errors from the session repository.
    @MainActor
    private func getConnectedCall(_ credentials: RoomCredentials) async throws -> CallFacade {
        let call = try await sessionRepository.createSession(credentials)
        call.connect()
        return call
    }
}

/// Mapping helper from transport response to domain credentials.
///
/// Converts ``RoomCredentialsResponse`` into domain ``RoomCredentials``
/// while attaching the `roomName` used for the request.
///
/// - SeeAlso: ``RoomCredentialsResponse``, ``RoomCredentials``
extension RoomCredentialsResponse {
    /// Converts this response to domain credentials, including the provided room name.
    ///
    /// - Parameter roomName: The room name associated with these credentials.
    /// - Returns: A domain ``RoomCredentials`` value.
    func asRoomCredentials(with roomName: String) -> RoomCredentials {
        .init(
            sessionId: sessionId,
            token: token,
            applicationId: apiKey,
            roomName: roomName,
            captionsId: captionsId)
    }
}
