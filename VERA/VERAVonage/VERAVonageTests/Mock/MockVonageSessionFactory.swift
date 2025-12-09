//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERACore
import VERAVonage

class MockVonageSessionFactory: SessionFactory {
    enum Error: Swift.Error {
        case sessionInitializationFailed
    }

    typealias Session = VonageSession
    var makeCalled = false
    func make(_ credentials: RoomCredentials) throws -> VonageSession {
        makeCalled = true
        guard let otSession = OTSession(applicationId: "appId", sessionId: "sessionId", delegate: nil) else {
            throw Error.sessionInitializationFailed
        }
        return VonageSession(session: otSession)
    }
}
