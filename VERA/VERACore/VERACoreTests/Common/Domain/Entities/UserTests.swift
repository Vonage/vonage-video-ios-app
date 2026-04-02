//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERACore

@Suite("User entity tests")
struct UserTests {

    @Test("User stores name correctly")
    func userStoresName() {
        let user = User(name: "Alice")

        #expect(user.name == "Alice")
    }

    @Test("User equality with same name")
    func userEqualitySameName() {
        let user1 = User(name: "Bob")
        let user2 = User(name: "Bob")

        #expect(user1 == user2)
    }

    @Test("User inequality with different name")
    func userInequalityDifferentName() {
        let user1 = User(name: "Alice")
        let user2 = User(name: "Bob")

        #expect(user1 != user2)
    }

    @Test("User with empty name")
    func userWithEmptyName() {
        let user = User(name: "")

        #expect(user.name == "")
    }

    @Test("User with special characters in name")
    func userWithSpecialChars() {
        let user = User(name: "José García-López")

        #expect(user.name == "José García-López")
    }

    @Test("User with very long name")
    func userWithLongName() {
        let longName = String(repeating: "A", count: 200)
        let user = User(name: longName)

        #expect(user.name == longName)
    }
}
