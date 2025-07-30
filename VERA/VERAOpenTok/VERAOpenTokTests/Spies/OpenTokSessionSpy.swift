//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERAOpenTok

class OpenTokSessionSpy: OpenTokSession {
    var connectCalled = false
    var disconnectCalled = false

    var recordedTokens: [String] = []

    init() {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!)
    }

    public override func connect(with token: String) throws {
        connectCalled = true
        recordedTokens.append(token)
        try super.connect(with: token)
    }

    public override func disconnect() throws {
        disconnectCalled = true
        try super.disconnect()
    }
}
