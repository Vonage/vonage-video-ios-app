//
//  Created by Vonage on 20/10/25.
//

import Foundation
import Testing
import VERACore

@Suite("Get initials test suite")
struct GetInitialsTests {

    @Test(
        "Extract initials from usernames",
        arguments: [
            ("", ""),
            ("a", "A"),
            ("hulk", "H"),
            ("peter     parker", "PP"),
            ("    ironman", "I"),
            ("the amazing spiderman", "TS"),
            ("🙈", ""),
            ("? what happen?", "WH"),
        ])
    func testInitials(
        _ pair: (username: String, expectedValue: String)
    ) throws {
        let initials = pair.username.getInitials()
        #expect(
            initials == pair.expectedValue,
            "\(pair.username) with initials \(initials) is not equal to \(pair.expectedValue)")
    }
}
