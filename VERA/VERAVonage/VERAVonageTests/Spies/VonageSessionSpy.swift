//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERAVonage

class VonageSessionSpy: VonageSession {
    var connectCalled = false
    var disconnectCalled = false
    var unpublishCalled = false
    var publishCalled = false

    var recordedTokens: [String] = []
    var unpublishedPublishers: [VonagePublisher] = []

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

        // Simulate successful connection by triggering the callback
        onSessionDidConnect?()
    }

    public override func disconnect() throws {
        disconnectCalled = true
        try super.disconnect()
    }

    public override func unpublish(publisher: VonagePublisher) throws {
        unpublishCalled = true
        unpublishedPublishers.append(publisher)
    }

    override func publish(publisher: VonagePublisher) throws {
        publishCalled = true
    }
}
