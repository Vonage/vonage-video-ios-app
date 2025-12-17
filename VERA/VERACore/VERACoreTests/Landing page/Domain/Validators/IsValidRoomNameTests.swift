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
            ("TestRoom", false),
            ("ROOM_NAME", false),
            ("MixedCaseRoom123", false),
            ("Hola-aseaspla", false),
            ("", false),
            ("room@name", false),
            ("room#name", false),
            ("room$name", false),
            ("  room    name", false),
            ("🙈", false),
            ("roomname🙈", false),
            ("roomname 🙈", false),
            ("roomnameroomnameroomnameroomnameroomnameroomnameroomnameroom", true),
            ("roomnameroomnameroomnameroomnameroomnameroomnameroomnameroomn", false),
        ])
    func validateRoomName(testCase: (String, Bool)) {
        let (roomName, expectedValid) = testCase
        let actualValid = roomName.isValidRoomName

        #expect(
            actualValid == expectedValid,
            """
            Room name '\(roomName)' should be \(expectedValid ? "valid" : "invalid"), \
            but was \(actualValid ? "valid" : "invalid")
            """
        )
    }
}
