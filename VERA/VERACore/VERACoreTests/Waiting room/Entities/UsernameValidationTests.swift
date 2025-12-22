//
//  Created by Vonage on 17/12/25.
//

import Foundation
import Testing
import VERACore

@Suite("Username validation test suite")
struct UsernameValidationTests {

    @Test(
        "Valid usernames should pass validation",
        arguments: [
            "John",
            "Jane Doe",
            "A",
            "User123",
            "  ValidUser  ",  // with surrounding whitespace
            "a" + String(repeating: "b", count: 59),  // exactly 60 characters
            "User with spaces",
            "12345",
        ])
    func testValidUsernames(_ username: String) {
        #expect(username.isValidUsername, "\(username) should be valid")
    }

    @Test(
        "Invalid usernames should fail validation",
        arguments: [
            "",
            "   ",
            "\n",
            "\t",
            "  \n  ",
            String(repeating: " ", count: 10),
            "a" + String(repeating: "b", count: 60),  // 61 characters (exceeds max)
            String(repeating: "x", count: 100),  // way too long
        ])
    func testInvalidUsernames(_ username: String) {
        #expect(!username.isValidUsername, "\(username) should be invalid")
    }

    @Test("Empty string is invalid")
    func testEmptyString() {
        let username = ""
        #expect(!username.isValidUsername)
    }

    @Test("Single character is valid")
    func testSingleCharacter() {
        let username = "A"
        #expect(username.isValidUsername)
    }

    @Test("Exact max length is valid")
    func testExactMaxLength() {
        let username = String(repeating: "a", count: 60)
        #expect(username.isValidUsername)
    }

    @Test("Over max length is invalid")
    func testOverMaxLength() {
        let username = String(repeating: "a", count: 61)
        #expect(!username.isValidUsername)
    }

    @Test("Whitespace only is invalid")
    func testWhitespaceOnly() {
        let username = "     "
        #expect(!username.isValidUsername)
    }

    @Test("Username with surrounding whitespace is valid after trim")
    func testSurroundingWhitespace() {
        let username = "  ValidUser  "
        #expect(username.isValidUsername)
    }

    @Test("Username with newlines only is invalid")
    func testNewlinesOnly() {
        let username = "\n\n\n"
        #expect(!username.isValidUsername)
    }

    @Test("Username with tabs only is invalid")
    func testTabsOnly() {
        let username = "\t\t\t"
        #expect(!username.isValidUsername)
    }

    @Test("Max username length constant is 60")
    func testMaxUsernameLength() {
        #expect(Username.maxUsernameLength == 60)
    }
}
