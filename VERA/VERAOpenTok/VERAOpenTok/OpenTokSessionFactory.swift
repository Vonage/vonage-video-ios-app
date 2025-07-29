//
//  Created by Vonage on 23/7/25.
//

import Foundation
import OpenTok
import VERACore

public final class OpenTokSessionFactory {

    public init() {}

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
