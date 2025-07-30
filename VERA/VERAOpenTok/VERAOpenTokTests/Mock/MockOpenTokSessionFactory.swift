//
//  Created by Vonage on 30/7/25.
//

import Foundation
import OpenTok
import VERACore
import VERAOpenTok

class MockOpenTokSessionFactory: SessionFactory {
    typealias Session = OpenTokSession
    var makeCalled = false
    func make(_ credentials: RoomCredentials) -> OpenTokSession {
        makeCalled = true
        let otSession = OTSession(applicationId: "appId", sessionId: "sessionId", delegate: nil)!
        return OpenTokSession(session: otSession)
    }
}
