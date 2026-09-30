//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

class VonageSessionSpy: VonageSession {
    var connectCalled = false
    var disconnectCalled = false
    var unpublishCalled = false
    var publishCalled = false
    var forceMuteError: Swift.Error?

    var recordedTokens: [String] = []
    var unpublishedPublishers: [VonagePublisher] = []
    var forceMutedStreams: [OTStream] = []

    init(token: String = "token") {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!,
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: token,
                applicationId: "applicationId",
                roomName: "roomName",
                sessionKey: "sessionKey"))
    }

    public override func connect() throws {
        connectCalled = true
        recordedTokens.append(token)
        try super.connect()

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

    override func forceMute(stream: OTStream) throws {
        if let forceMuteError {
            throw forceMuteError
        }
        forceMutedStreams.append(stream)
    }
}
