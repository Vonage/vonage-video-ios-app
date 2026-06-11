//
//  Created by Vonage on 8/6/26.
//

import Foundation
import VERADomain
import VERAVonage

enum E2ECallParamsBuilder {
    static func callParams(from credentials: RoomCredentials?) -> [String: Any] {
        guard let credentials else { return [:] }

        return [
            VonageCallParams.username.rawValue: "Test User",
            VonageCallParams.roomName.rawValue: credentials.roomName,
            VonageCallParams.callID.rawValue: UUID().uuidString,
            VonageCallParams.applicationId.rawValue: credentials.applicationId,
            VonageCallParams.sessionId.rawValue: credentials.sessionId,
            VonageCallParams.token.rawValue: credentials.token,
        ]
    }
}
