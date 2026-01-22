//
//  Created by Vonage on 22/1/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Meeting room url tests")
struct MeetingRoomURLExtensionTests {
    @Test(
        "meetingRoomURL appends room path and room name correctly",
        arguments: [
            (baseURL: "https://api.example.com", roomName: "test-room", expected: "https://api.example.com/room/test-room"),
            (baseURL: "https://api.example.com", roomName: "my-room-123", expected: "https://api.example.com/room/my-room-123"),
            (baseURL: "https://api.example.com/v1", roomName: "conference", expected: "https://api.example.com/v1/room/conference"),
            (baseURL: "http://localhost:3000", roomName: "local-meeting", expected: "http://localhost:3000/room/local-meeting"),
        ])
    func meetingRoomURLAppendsCorrectPath(baseURL: String, roomName: String, expected: String) async throws {
        let url = URL(string: baseURL)!
        let result = url.meetingRoomURL(roomName)
        
        #expect(result.absoluteString == expected)
    }
}
