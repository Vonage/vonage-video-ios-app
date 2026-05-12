//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERACore
import VERADomain

public class MockRoomCredentialsRepository: RoomCredentialsRepository {

    private var response: RoomCredentialsResponse

    public init(response: RoomCredentialsResponse) {
        self.response = response
    }

    public func getRoomCredentials(
        _ request: RoomCredentialsRequest
    ) async throws -> RoomCredentialsResponse {
        response
    }
}

public func makeMockRoomCredentialsRepository(
    _ response: RoomCredentialsResponse = .init(
        sessionId: "a-sessionId", token: "a-tokenId", apiKey: "anAPIKey", sessionKey: "aSessionKey")
) -> MockRoomCredentialsRepository {
    MockRoomCredentialsRepository(response: response)
}
