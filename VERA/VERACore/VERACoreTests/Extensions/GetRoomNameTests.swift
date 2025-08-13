//
//  Created by Vonage on 13/8/25.
//

import Foundation
import Testing

@Suite("URL get room name tests")
struct GetRoomNameTests {
    
    // MARK: - Test Data
    
    private let vonageBaseURL = URL(string: "https://meet.vonagenetworks.net")!
    private let otherBaseURL = URL(string: "https://other-domain.com")!
    
    // MARK: - Valid Room Name Tests
    
    @Test("Extract valid room name from URL")
    func extractValidRoomName() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/heart-of-gold")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "heart-of-gold")
    }
    
    @Test("Extract room name with numbers and dashes")
    func extractRoomNameWithNumbersAndDashes() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/room-123-test")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "room-123-test")
    }
    
    @Test("Extract room name with underscores")
    func extractRoomNameWithUnderscores() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/my_room_name")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "my_room_name")
    }
    
    @Test("Extract single character room name")
    func extractSingleCharacterRoomName() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/a")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "a")
    }
    
    // MARK: - Invalid Host Tests
    
    @Test("Return nil for different host")
    func returnNilForDifferentHost() async throws {
        let url = URL(string: "https://other-domain.com/room-name")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }
    
    // MARK: - Invalid Path Tests
    
    @Test("Return nil for empty path")
    func returnNilForEmptyPath() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }
    
    @Test("Return nil for root path only")
    func returnNilForRootPathOnly() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }
    
    @Test("Return nil for sub-paths")
    func returnNilForSubPaths() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/room/subroom")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }
    
    @Test("Return nil for hidden files")
    func returnNilForHiddenFiles() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/.well-known")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil)
    }
    
    // MARK: - Query Parameters and Fragments Tests
    
    @Test("Extract room name ignoring query parameters")
    func extractRoomNameIgnoringQueryParameters() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/test-room?param=value")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "test-room")
    }
    
    @Test("Extract room name ignoring fragments")
    func extractRoomNameIgnoringFragments() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/test-room#section")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == "test-room")
    }
    
    // MARK: - Edge Cases
    
    @Test("Return nil for malformed URL path")
    func returnNilForMalformedURLPath() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net//double-slash")!
        let roomName = url.getRoomName(from: vonageBaseURL)
        #expect(roomName == nil) // Should fail validation due to empty component
    }
    
    // MARK: - Different Base URL Tests
    
    @Test("Work with different base URL")
    func workWithDifferentBaseURL() async throws {
        let url = URL(string: "https://other-domain.com/my-room")!
        let roomName = url.getRoomName(from: otherBaseURL)
        #expect(roomName == "my-room")
    }
    
    @Test("Return nil when using wrong base URL")
    func returnNilWhenUsingWrongBaseURL() async throws {
        let url = URL(string: "https://meet.vonagenetworks.net/my-room")!
        let roomName = url.getRoomName(from: otherBaseURL)
        #expect(roomName == nil)
    }
}
