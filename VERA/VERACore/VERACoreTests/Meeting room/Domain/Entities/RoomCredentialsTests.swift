//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERACore

@Suite("RoomCredentials tests")
struct RoomCredentialsTests {

    @Test("RoomCredentials stores properties correctly")
    func roomCredentialsProperties() {
        let credentials = RoomCredentials(
            sessionId: "session-123",
            token: "token-abc",
            applicationId: "app-456",
            roomName: "my-room")

        #expect(credentials.sessionId == "session-123")
        #expect(credentials.token == "token-abc")
        #expect(credentials.applicationId == "app-456")
        #expect(credentials.roomName == "my-room")
        #expect(credentials.captionsId == nil)
    }

    @Test("RoomCredentials with captionsId")
    func roomCredentialsWithCaptionsId() {
        let credentials = RoomCredentials(
            sessionId: "session-123",
            token: "token-abc",
            applicationId: "app-456",
            roomName: "my-room",
            captionsId: "captions-789")

        #expect(credentials.captionsId == "captions-789")
    }

    @Test("RoomCredentials description includes all fields")
    func roomCredentialsDescription() {
        let credentials = RoomCredentials(
            sessionId: "session-123",
            token: "token-abc",
            applicationId: "app-456",
            roomName: "my-room")

        let description = credentials.description
        #expect(description.contains("app-456"))
        #expect(description.contains("session-123"))
        #expect(description.contains("token-abc"))
        #expect(description.contains("my-room"))
    }
}
