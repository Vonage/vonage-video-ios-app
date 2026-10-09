//
//  Created by Vonage on 27/9/26.
//

import Foundation
import OpenTok
import VERACore
import VERADomain
import VERAVonage

final class MockVonageSessionProvider: SessionProvider {
    enum Error: Swift.Error {
        case sessionInitializationFailed
    }

    typealias Session = VonageSession

    private(set) var makeSessionCalled = false
    var errorToThrow: Swift.Error?

    func makeSession(for roomName: RoomName) async throws -> VonageSession {
        makeSessionCalled = true
        if let errorToThrow {
            throw errorToThrow
        }
        guard let otSession = OTSession(applicationId: "appId", sessionId: "sessionId", delegate: nil) else {
            throw Error.sessionInitializationFailed
        }
        return VonageSession(
            session: otSession,
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: "token",
                applicationId: "appId",
                roomName: roomName,
                sessionKey: "sessionKey"))
    }
}
