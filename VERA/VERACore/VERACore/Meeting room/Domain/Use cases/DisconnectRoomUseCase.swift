//
//  Created by Vonage on 28/7/25.
//

import Foundation

/// Use case for disconnecting the current call session.
///
/// `DisconnectRoomUseCase` encapsulates the teardown operation. It is intentionally minimal,
/// providing a single `callAsFunction()` entry point to trigger a disconnect on the active call.
///
/// - SeeAlso: ``DefaultDisconnectRoomUseCase``, ``SessionRepository``, ``CallFacade/disconnect()``
public protocol DisconnectRoomUseCase {
    /// Disconnects the current call, if any.
    ///
    /// - Throws: Any error thrown by the underlying call’s `disconnect()` implementation.
    func callAsFunction() async throws
}

/// Default implementation of ``DisconnectRoomUseCase``.
///
/// Resolves the current call from the session repository and triggers an async disconnect.
/// If there is no active call, the operation is a no-op.
public final class DefaultDisconnectRoomUseCase: DisconnectRoomUseCase {

    private let sessionRepository: SessionRepository

    /// Creates a new use case with the required repository.
    ///
    /// - Parameter sessionRepository: Repository providing the current call façade.
    public init(
        sessionRepository: SessionRepository
    ) {
        self.sessionRepository = sessionRepository
    }

    /// Disconnects the current call if present.
    ///
    /// Delegates to the active call façade’s ``CallFacade/disconnect()`` method.
    ///
    /// - Throws: Any error thrown by the call’s disconnect. No-op if no active call.
    public func callAsFunction() async throws {
        try await sessionRepository.currentCall?.disconnect()
    }
}
