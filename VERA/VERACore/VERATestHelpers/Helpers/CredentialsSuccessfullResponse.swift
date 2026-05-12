//
//  Created by Vonage on 30/7/25.
//

import Foundation

/// Produces a tRPC-wrapped `createSession` JSON response.
public func makeCreateSessionJSONResponse(
    sessionId: String = "sessionId",
    sessionKey: String = "sessionKey",
    applicationId: String = "applicationId"
) throws -> Data {
    let json: [String: Any] = [
        "result": [
            "data": [
                "sessionId": sessionId,
                "sessionKey": sessionKey,
                "applicationId": applicationId
            ]
        ]
    ]
    return try JSONSerialization.data(withJSONObject: json)
}

/// Produces a tRPC-wrapped `joinSession` JSON response.
public func makeJoinSessionJSONResponse(
    token: String = "token"
) throws -> Data {
    let json: [String: Any] = [
        "result": [
            "data": [
                "token": token
            ]
        ]
    ]
    return try JSONSerialization.data(withJSONObject: json)
}
