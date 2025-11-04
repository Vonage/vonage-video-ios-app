//
//  Created by Vonage on 9/7/25.
//

import Foundation
import Testing

@testable import VERACore

@Suite("Room Name Validation")
struct RoomNameValidatorTests {

    @Test(
        "All test cases",
        arguments: [
            ("a", true),
            ("room_name", true),
            ("room+name", true),
            ("another-room_name", true),
            ("123roomname", true),
            ("TestRoom", true),  // Now valid - uppercase letters
            ("ROOM_NAME", true),  // Now valid - all uppercase
            ("MixedCaseRoom123", true),  // Now valid - mixed case
            ("Hola-aseaspla", true),  // Now valid - the actual UI case
            ("", false),
            ("room@name", false),
            ("room#name", false),
            ("room$name", false),
            ("  room    name", false),
            ("🙈", false),
            ("roomname🙈", false),
            ("roomname 🙈", false),
        ])
    func validateRoomName(testCase: (String, Bool)) {
        let (roomName, expectedValid) = testCase
        let actualValid = roomName.isValidRoomName
        let modernValid = roomName.isValidRoomNameModern()
        let legacyValid = roomName.isValidRoomNameLegacy()

        #expect(
            actualValid == expectedValid,
            """
            Room name '\(roomName)' should be \(expectedValid ? "valid" : "invalid"), \
            but was \(actualValid ? "valid" : "invalid")
            """
        )

        #expect(
            modernValid == expectedValid,
            """
            Room name '\(roomName)' should be \(expectedValid ? "valid" : "invalid"), \
            but was \(actualValid ? "valid" : "invalid")
            """
        )

        #expect(
            legacyValid == expectedValid,
            """
            Room name '\(roomName)' should be \(expectedValid ? "valid" : "invalid"), \
            but was \(actualValid ? "valid" : "invalid")
            """
        )
    }
}
