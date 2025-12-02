//
//  Created by Vonage on 23/7/25.
//

import Foundation
import OpenTok
import VERACore

public final class OpenTokSessionFactory: SessionFactory {

    public enum Error: Swift.Error {
        case failedSessionInitialization
    }

    public init() {}

    public func make(_ sessionCredentials: RoomCredentials) throws -> OpenTokSession {
        let settings = OTSessionSettings()

        // Setting singlePeerConnection to true prevents complex workarounds and issues
        // when joining rooms with many participants by using a single peer connection
        // instead of multiple peer connections which can cause WebRTC limitations
        settings.singlePeerConnection = true
        settings.sessionMigration = true

        let otSession = OTSession(
            applicationId: sessionCredentials.applicationId,
            sessionId: sessionCredentials.sessionId,
            delegate: nil,
            settings: settings)

        guard let unwrappedSession = otSession else {
            throw Error.failedSessionInitialization
        }

        let session = OpenTokSession(session: unwrappedSession)
        unwrappedSession.delegate = session
        return session
    }
}
