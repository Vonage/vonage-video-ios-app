//
//  Created by Vonage on 29/7/25.
//

import Foundation
import OpenTok
import VERADomain
import VERAVonage

class ThrowingVonageSession: VonageSession {

    enum Error: Swift.Error {
        case any
    }

    init() {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!,
            credentials: RoomCredentials(
                sessionId: "sessionId",
                token: "token",
                applicationId: "applicationId",
                roomName: "roomName",
                sessionKey: "sessionKey"))
    }

    public override func connect() throws {
        throw Error.any
    }

    public override func disconnect() throws {
        throw Error.any
    }
}
