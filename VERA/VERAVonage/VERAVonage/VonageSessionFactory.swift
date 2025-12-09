//
//  Created by Vonage on 23/7/25.
//

import Foundation
import OpenTok
import VERACore

/// Creates configured `VonageSession` instances from `RoomCredentials`.
///
/// This factory encapsulates the Vonage `OTSession` setup logic, including
/// session settings that optimize multi-participant rooms (single peer connection)
/// and support seamless migration. It then wraps the underlying `OTSession` in
/// an `VonageSession` which conforms to `Session`.
public final class VonageSessionFactory: SessionFactory {

    /// Errors that can occur during Vonage session creation.
    public enum Error: Swift.Error {
        /// The underlying `OTSession` failed to initialize.
        case failedSessionInitialization
    }

    /// Creates a new `VonageSessionFactory`.
    public init() {}

    /// Builds an `VonageSession` using the provided room credentials.
    ///
    /// This method configures `OTSessionSettings` to:
    /// - Enable `singlePeerConnection`: reduces WebRTC complexity in rooms with many participants.
    /// - Enable `sessionMigration`: supports seamless reconnection/migration scenarios.
    ///
    /// It then creates an `OTSession` with the given `applicationId` and `sessionId`,
    /// wraps it into an `VonageSession`, and assigns the wrapper as the `OTSession` delegate.
    ///
    /// - Parameters:
    ///   - sessionCredentials: The credentials required to create the Vonage session, including `applicationId` and `sessionId`.
    /// - Returns: A configured `VonageSession` ready to `connect()`.
    /// - Throws: ``VonageSessionFactory/Error/failedSessionInitialization`` if the underlying `OTSession` could not be created.
    /// - Important: This does not connect the session; call `connect()` on the returned `VonageSession`.
    /// - SeeAlso: ``RoomCredentials``, ``VonageSession``
    public func make(_ sessionCredentials: RoomCredentials) throws -> VonageSession {
        let settings = OTSessionSettings()

        // Setting singlePeerConnection to true prevents complex workarounds and issues
        // when joining rooms with many participants by using a single peer connection
        // instead of multiple peer connections which can cause WebRTC limitations
        settings.singlePeerConnection = true
        // Session migration is recommended for long running sessions
        settings.sessionMigration = true

        let otSession = OTSession(
            applicationId: sessionCredentials.applicationId,
            sessionId: sessionCredentials.sessionId,
            delegate: nil,
            settings: settings
        )

        guard let unwrappedSession = otSession else {
            throw Error.failedSessionInitialization
        }

        let session = VonageSession(session: unwrappedSession)
        unwrappedSession.delegate = session
        return session
    }
}
