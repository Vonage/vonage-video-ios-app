//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERACore

public class MockRoomCredentialsRepository: RoomCredentialsRepository {
    
    private var response: RoomCredentialsResponse
    
    public init(response: RoomCredentialsResponse) {
        self.response = response
    }
    
    public func getRoomCredentials(
        _ request: VERACore.RoomCredentialsRequest
    ) async throws -> VERACore.RoomCredentialsResponse {
        response
    }
}

public func makeMockRoomCredentialsRepository(
    _ response: RoomCredentialsResponse = .init(
        sessionId: "a-sessionId", token: "a-tokenId", apiKey: "anAPIKey")
) -> MockRoomCredentialsRepository {
    MockRoomCredentialsRepository(response: response)
}
