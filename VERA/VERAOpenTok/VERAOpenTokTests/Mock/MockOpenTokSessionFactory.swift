//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERACore
import VERAOpenTok

class MockOpenTokSessionFactory: SessionFactory {
    enum Error: Swift.Error {
        case sessionInitializationFailed
    }

    typealias Session = OpenTokSession
    var makeCalled = false
    func make(_ credentials: RoomCredentials) throws -> OpenTokSession {
        makeCalled = true
        guard let otSession = OTSession(applicationId: "appId", sessionId: "sessionId", delegate: nil) else {
            throw Error.sessionInitializationFailed
        }
        return OpenTokSession(session: otSession)
    }
}
