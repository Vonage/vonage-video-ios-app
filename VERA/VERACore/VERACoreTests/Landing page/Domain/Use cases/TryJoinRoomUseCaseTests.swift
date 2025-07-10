//
//  Created by Vonage on 9/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Try join room use case tests")
struct TryJoinRoomUseCaseTests {

    // MARK: - Success Cases

    @Test("Should succeed with valid lowercase room name")
    func shouldSucceedWithValidLowercaseRoomName() async throws {
        let sut = makeSUT()

        // Should not throw for valid room name
        try await sut.invoke("validroomname")
    }

    @Test("Should succeed with room name containing numbers")
    func shouldSucceedWithRoomNameContainingNumbers() async throws {
        let sut = makeSUT()

        try await sut.invoke("room123")
    }

    @Test("Should succeed with room name containing hyphens")
    func shouldSucceedWithRoomNameContainingHyphens() async throws {
        let sut = makeSUT()

        try await sut.invoke("my-room-name")
    }

    @Test("Should succeed with room name containing underscores")
    func shouldSucceedWithRoomNameContainingUnderscores() async throws {
        let sut = makeSUT()

        try await sut.invoke("my_room_name")
    }

    @Test("Should succeed with room name containing plus signs")
    func shouldSucceedWithRoomNameContainingPlusSigns() async throws {
        let sut = makeSUT()

        try await sut.invoke("room+name")
    }

    @Test("Should succeed with mixed valid characters")
    func shouldSucceedWithMixedValidCharacters() async throws {
        let sut = makeSUT()

        try await sut.invoke("room_123-test+name")
    }

    @Test("Should succeed with minimum length room name")
    func shouldSucceedWithMinimumLengthRoomName() async throws {
        let sut = makeSUT()

        try await sut.invoke("a")
    }

    @Test("Should succeed with numbers only")
    func shouldSucceedWithNumbersOnly() async throws {
        let sut = makeSUT()

        try await sut.invoke("12345")
    }

    @Test("Should succeed with underscores only")
    func shouldSucceedWithUnderscoresOnly() async throws {
        let sut = makeSUT()

        try await sut.invoke("___")
    }

    @Test("Should succeed with hyphens only")
    func shouldSucceedWithHyphensOnly() async throws {
        let sut = makeSUT()

        try await sut.invoke("---")
    }

    @Test("Should succeed with plus signs only")
    func shouldSucceedWithPlusSignsOnly() async throws {
        let sut = makeSUT()

        try await sut.invoke("+++")
    }

    @Test("Should succeed with long room name")
    func shouldSucceedWithLongRoomName() async throws {
        let sut = makeSUT()

        let longRoomName = String(repeating: "a", count: 100)
        try await sut.invoke(longRoomName)
    }

    // MARK: - Failure Cases

    @Test("Should throw invalidRoomName error for empty string")
    func shouldThrowInvalidRoomNameErrorForEmptyString() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("")
        }
    }

    @Test("Should throw invalidRoomName error for whitespace only")
    func shouldThrowInvalidRoomNameErrorForWhitespaceOnly() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("   ")
        }
    }

    @Test("Should throw invalidRoomName error for room name with spaces")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithSpaces() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room name with spaces")
        }
    }

    @Test("Should throw invalidRoomName error for uppercase letters")
    func shouldThrowInvalidRoomNameErrorForUppercaseLetters() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("RoomName")
        }
    }

    @Test("Should throw invalidRoomName error for mixed case letters")
    func shouldThrowInvalidRoomNameErrorForMixedCaseLetters() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("Room123")
        }
    }

    @Test("Should throw invalidRoomName error for room name with special characters")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithSpecialCharacters() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room@name")
        }
    }

    @Test("Should throw invalidRoomName error for room name with emojis")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithEmojis() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("roomname🙈")
        }
    }

    @Test("Should throw invalidRoomName error for room name with dots")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithDots() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room.name")
        }
    }

    @Test("Should throw invalidRoomName error for room name with hash")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithHash() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room#name")
        }
    }

    @Test("Should throw invalidRoomName error for room name with percent")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithPercent() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room%name")
        }
    }

    // MARK: - Edge Cases

    @Test("Should throw invalidRoomName error for room name with newlines")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithNewlines() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room\nname")
        }
    }

    @Test("Should throw invalidRoomName error for room name with tabs")
    func shouldThrowInvalidRoomNameErrorForRoomNameWithTabs() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("room\tname")
        }
    }

    @Test("Should succeed with consecutive hyphens")
    func shouldSucceedWithConsecutiveHyphens() async throws {
        let sut = makeSUT()

        try await sut.invoke("room--name")
    }

    @Test("Should succeed with consecutive underscores")
    func shouldSucceedWithConsecutiveUnderscores() async throws {
        let sut = makeSUT()

        try await sut.invoke("room__name")
    }

    @Test("Should succeed with consecutive plus signs")
    func shouldSucceedWithConsecutivePlusSigns() async throws {
        let sut = makeSUT()

        try await sut.invoke("room++name")
    }

    @Test("Should succeed with room name starting with number")
    func shouldSucceedWithRoomNameStartingWithNumber() async throws {
        let sut = makeSUT()

        try await sut.invoke("123room")
    }

    @Test("Should succeed with room name starting with hyphen")
    func shouldSucceedWithRoomNameStartingWithHyphen() async throws {
        let sut = makeSUT()

        try await sut.invoke("-roomname")
    }

    @Test("Should succeed with room name starting with underscore")
    func shouldSucceedWithRoomNameStartingWithUnderscore() async throws {
        let sut = makeSUT()

        try await sut.invoke("_roomname")
    }

    @Test("Should succeed with room name starting with plus")
    func shouldSucceedWithRoomNameStartingWithPlus() async throws {
        let sut = makeSUT()

        try await sut.invoke("+roomname")
    }

    @Test("Should succeed with room name ending with hyphen")
    func shouldSucceedWithRoomNameEndingWithHyphen() async throws {
        let sut = makeSUT()

        try await sut.invoke("roomname-")
    }

    @Test("Should succeed with room name ending with underscore")
    func shouldSucceedWithRoomNameEndingWithUnderscore() async throws {
        let sut = makeSUT()

        try await sut.invoke("roomname_")
    }

    @Test("Should succeed with room name ending with plus")
    func shouldSucceedWithRoomNameEndingWithPlus() async throws {
        let sut = makeSUT()

        try await sut.invoke("roomname+")
    }

    // MARK: - Parameterized Tests

    @Test(
        "Should throw invalidRoomName error for invalid names",
        arguments: [
            "",
            " ",
            "   ",
            "Room",
            "ROOM",
            "Room123",
            "ROOM123",
            "room name",
            "room@name",
            "room#name",
            "room$name",
            "room%name",
            "room&name",
            "room*name",
            "room=name",
            "room[name",
            "room]name",
            "room{name",
            "room}name",
            "room|name",
            "room\\name",
            "room:name",
            "room;name",
            "room\"name",
            "room'name",
            "room<name",
            "room>name",
            "room,name",
            "room.name",
            "room?name",
            "room/name",
            "room~name",
            "room`name",
            "room!name",
            "room\nname",
            "room\tname",
            "roomname🙈",
            "roomname 🙈",
        ])
    func shouldThrowInvalidRoomNameErrorForInvalidNames(invalidName: String) async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke(invalidName)
        }
    }

    @Test(
        "Should succeed with valid room names",
        arguments: [
            "a",
            "z",
            "0",
            "9",
            "_",
            "+",
            "-",
            "abc",
            "123",
            "abc123",
            "room123",
            "my-room",
            "my_room",
            "room+name",
            "room-123",
            "room_123",
            "room+123",
            "room-test-123",
            "room_test_123",
            "room+test+123",
            "a1b2c3",
            "validroomname",
            "valid-room-name",
            "valid_room_name",
            "valid+room+name",
            "123room",
            "-roomname",
            "_roomname",
            "+roomname",
            "roomname-",
            "roomname_",
            "roomname+",
            "room--name",
            "room__name",
            "room++name",
            "___",
            "---",
            "+++",
            "12345",
            String(repeating: "a", count: 100),
        ])
    func shouldSucceedWithValidRoomNames(validName: String) async throws {
        let sut = makeSUT()

        // Should not throw for valid room names
        try await sut.invoke(validName)
    }

    // MARK: - Performance Tests

    @Test("Should validate room name quickly")
    func shouldValidateRoomNameQuickly() async throws {
        let sut = makeSUT()
        let startTime = CFAbsoluteTimeGetCurrent()

        try await sut.invoke("validroomname")

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 0.001, "Room name validation should be very fast")
    }

    // MARK: - Boundary Tests

    @Test("Should handle very long valid room names")
    func shouldHandleVeryLongValidRoomNames() async throws {
        let sut = makeSUT()

        let veryLongRoomName = String(repeating: "a", count: 1000)
        try await sut.invoke(veryLongRoomName)
    }

    @Test("Should handle room names with all valid characters")
    func shouldHandleRoomNamesWithAllValidCharacters() async throws {
        let sut = makeSUT()

        try await sut.invoke("abcdefghijklmnopqrstuvwxyz0123456789_+-")
    }

    // MARK: - Error Handling Tests

    @Test("Should throw correct error type for invalid room name")
    func shouldThrowCorrectErrorTypeForInvalidRoomName() async throws {
        let sut = makeSUT()

        do {
            try await sut.invoke("INVALID")
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is TryJoinRoomUseCase.Error)
            if let useCaseError = error as? TryJoinRoomUseCase.Error {
                #expect(useCaseError == .invalidRoomName)
            }
        }
    }

    // MARK: - SUT Factory

    func makeSUT() -> TryJoinRoomUseCase {
        return TryJoinRoomUseCase()
    }
}
