//
//  Created by Vonage on 23/7/25.
//

import Foundation
import OpenTok
import VERACore

final class OpenTokSessionFactory {
    func make(_ sessionCredentials: RoomCredentials) -> OpenTokSession {
        let otSession = OTSession(
            applicationId: sessionCredentials.apiKey,
            sessionId: sessionCredentials.sessionId,
            delegate: nil)!

        let session = OpenTokSession(session: otSession)
        otSession.delegate = session
        return session
    }
}

final class OpenTokSession: NSObject, OTSessionDelegate {
    private let session: OTSession

    init(session: OTSession) {
        self.session = session
    }

    func session(_ session: OTSession, didFailWithError error: OTError) {

    }

    func session(_ session: OTSession, streamCreated stream: OTStream) {

    }

    func session(_ session: OTSession, streamDestroyed stream: OTStream) {

    }

    func sessionDidConnect(_ session: OTSession) {

    }

    func sessionDidDisconnect(_ session: OTSession) {

    }
}
