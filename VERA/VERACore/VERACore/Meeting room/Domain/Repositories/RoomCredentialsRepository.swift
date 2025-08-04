//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct RoomCredentialsResponse: Decodable {
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

public struct RoomCredentialsRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public protocol RoomCredentialsRepository {
    func getRoomCredentials(_ request: RoomCredentialsRequest) async throws -> RoomCredentialsResponse
}
