//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERAOpenTok
import OpenTok

class ThrowingOpenTokSession: OpenTokSession {

    enum Error: Swift.Error {
        case any
    }

    init() {
        super.init(
            session: OTSession(
                applicationId: "applicationId",
                sessionId: "sessionId",
                delegate: nil)!)
    }

    public override func connect(with token: String) throws {
        throw Error.any
    }

    public override func disconnect() throws {
        throw Error.any
    }
}
