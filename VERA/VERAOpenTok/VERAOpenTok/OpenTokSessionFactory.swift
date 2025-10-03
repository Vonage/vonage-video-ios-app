//
//  Created by Vonage on 23/7/25.
//

import Foundation
import OpenTok
import VERACore

public final class OpenTokSessionFactory: SessionFactory {

    public init() {}

    public func make(_ sessionCredentials: RoomCredentials) -> OpenTokSession {
        assertMainThread()

        let settings = OTSessionSettings()

        // Setting singlePeerConnection to true prevents complex workarounds and issues
        // when joining rooms with many participants by using a single peer connection
        // instead of multiple peer connections which can cause WebRTC limitations
        settings.singlePeerConnection = true

        let otSession = OTSession(
            applicationId: sessionCredentials.applicationId,
            sessionId: sessionCredentials.sessionId,
            delegate: nil,
            settings: settings)!

        let session = OpenTokSession(session: otSession)
        otSession.delegate = session
        return session
    }
}
