//
//  Created by Vonage on 13/8/25.
//

import Foundation
import Testing

@Suite("URL get room name tests")
struct GetRoomNameTests {

    // MARK: - Test Data

    private let vonageBaseURL = URL(string: "https://video.vonage.com/")!
    private let otherBaseURL = URL(string: "https://other-domain.com")!

    // MARK: - Valid Room Name Tests

    @Test(
        "Extract valid room name from URL",
        arguments: [
            URL(string: "https://video.vonage.com/room/heart-of-gold")!,
            URL(string: "https://video.vonage.com/waiting-room/heart-of-gold")!,
        ])
    func extractValidRoomName(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "heart-of-gold")
    }

    @Test(
        "Extract valid room name from URL with extra path element",
        arguments: [
            URL(string: "https://video.vonage.com/room/heart-of-gold/extra")!,
            URL(string: "https://video.vonage.com/waiting-room/heart-of-gold/extra")!,
        ])
    func extractRoomNameEvenIfPathHasExtraElements(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "heart-of-gold")
    }

    @Test(
        "Extract room name with numbers and dashes",
        arguments: [
            URL(string: "https://video.vonage.com/room/room-123-test")!,
            URL(string: "https://video.vonage.com/waiting-room/room-123-test")!,
        ])
    func extractRoomNameWithNumbersAndDashes(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "room-123-test")
    }

    @Test(
        "Extract room name with underscores",
        arguments: [
            URL(string: "https://video.vonage.com/room/my_room_name")!,
            URL(string: "https://video.vonage.com/waiting-room/my_room_name")!,
        ])
    func extractRoomNameWithUnderscores(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "my_room_name")
    }

    @Test(
        "Extract single character room name",
        arguments: [
            URL(string: "https://video.vonage.com/room/a")!,
            URL(string: "https://video.vonage.com/waiting-room/a")!,
        ])
    func extractSingleCharacterRoomName(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "a")
    }

    // MARK: - Invalid Host Tests

    @Test(
        "Return nil for different host",
        arguments: [
            URL(string: "https://other-domain.com/room/room-name")!,
            URL(string: "https://other-domain.com/waiting-room/room-name")!,
        ])
    func returnNilForDifferentHost(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }

    // MARK: - Invalid Path Tests

    @Test(
        "Return nil if no room name is specified",
        arguments: [
            URL(string: "https://video.vonage.com/room/")!,
            URL(string: "https://video.vonage.com/waiting-room/")!,
        ])
    func returnNilForEmptyPath(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }

    @Test("Return nil for empty path")
    func returnNilForEmptyPath() async throws {
        let url = URL(string: "https://video.vonage.com/")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }

    @Test("Return nil for root path only")
    func returnNilForRootPathOnly() async throws {
        let url = URL(string: "https://video.vonage.com")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }

    @Test("Return nil for hidden files")
    func returnNilForHiddenFiles() async throws {
        let url = URL(string: "https://video.vonage.com/.well-known")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }

    // MARK: - Query Parameters and Fragments Tests

    @Test(
        "Extract room name ignoring query parameters",
        arguments: [
            URL(string: "https://video.vonage.com/room/heart-of-gold?param=value")!,
            URL(string: "https://video.vonage.com/waiting-room/heart-of-gold?param=value")!,
        ])
    func extractRoomNameIgnoringQueryParameters(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "heart-of-gold")
    }

    @Test(
        "Extract room name ignoring fragments",
        arguments: [
            URL(string: "https://video.vonage.com/room/heart-of-gold#section")!,
            URL(string: "https://video.vonage.com/waiting-room/heart-of-gold#section")!,
        ])
    func extractRoomNameIgnoringFragments(_ url: URL) async throws {
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "heart-of-gold")
    }

    // MARK: - Edge Cases

    @Test("Return nil for malformed URL path")
    func returnNilForMalformedURLPath() async throws {
        let url = URL(string: "https://video.vonage.com//double-slash")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)  // Should fail validation due to empty component
    }
}
