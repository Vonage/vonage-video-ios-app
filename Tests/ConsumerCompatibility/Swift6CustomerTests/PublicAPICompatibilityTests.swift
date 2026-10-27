import Foundation
import Testing
import VERAMeetingRoomSDK

@Suite("Swift 6 customer public API")
struct PublicAPICompatibilityTests {
    @MainActor
    @Test("Customer UI code configures the public builder without connecting")
    func configuresMeeting() throws {
        let url = try #require(URL(string: "https://example.invalid"))
        let builder = MeetingRoomBuilder(baseURL: url, roomName: "customer-room")
        let configured = builder.enabledFeatures([.chat, .captions, .reactions])
        #expect(configured === builder)
    }

    @Test("An asynchronous caller can enter UI ownership explicitly")
    func configuresMeetingFromBackgroundCaller() async throws {
        try await Task.detached {
            try await MainActor.run {
                let url = try #require(URL(string: "https://example.invalid"))
                let builder = MeetingRoomBuilder(baseURL: url, roomName: "customer-room")
                #expect(builder.enabledFeatures([]) === builder)
            }
        }.value
    }
}
