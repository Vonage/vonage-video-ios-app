//
//  Created by Vonage on 30/7/25.
//

import Foundation

/// Produces a tRPC-wrapped `createSessionAndJoin` JSON response.
public func makeCreateSessionAndJoinJSONResponse(
    sessionId: String = "sessionId",
    sessionKey: String = "sessionKey",
    applicationId: String = "applicationId",
    token: String = "token"
) throws -> Data {
    let json: [String: Any] = [
        "result": [
            "data": [
                "sessionId": sessionId,
                "sessionKey": sessionKey,
                "applicationId": applicationId,
                "token": token,
            ]
        ]
    ]
    return try JSONSerialization.data(withJSONObject: json)
}
