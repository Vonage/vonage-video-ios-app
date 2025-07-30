//
//  Created by Vonage on 30/7/25.
//

import Foundation

public struct CredentialsSuccessfullResponse: Codable {
    public let sessionId: String
    public let token: String
    public let apiKey: String
    public let captionsId: String?

    public init(
        sessionId: String,
        token: String,
        apiKey: String,
        captionsId: String? = nil
    ) {
        self.sessionId = sessionId
        self.token = token
        self.apiKey = apiKey
        self.captionsId = captionsId
    }
}

public func makeCredentialsJSONResponse(
    sessionId: String = "sessionId",
    token: String = "token",
    apiKey: String = "apiKey",
    captionsId: String? = "captionsId"
) -> Data {
    let response = CredentialsSuccessfullResponse(
        sessionId: sessionId,
        token: token,
        apiKey: apiKey,
        captionsId: captionsId
    )

    return try! JSONEncoder().encode(response)
}
