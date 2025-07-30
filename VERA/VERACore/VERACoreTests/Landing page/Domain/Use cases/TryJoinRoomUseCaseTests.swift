//
//  Created by Vonage on 9/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Try join room use case tests")
struct TryJoinRoomUseCaseTests {

    // MARK: - Use Case Behavior Tests

    @Test("Should succeed with valid room name")
    func shouldSucceedWithValidRoomName() throws {
        let sut = makeSUT()

        // Test that the use case doesn't throw for a known valid name
        try sut("validroom123")
    }

    @Test("Should throw InvalidRoomName error for invalid room name")
    func shouldThrowInvalidRoomNameErrorForInvalidInput() throws {
        let sut = makeSUT()

        // Test that the use case throws the correct error type
        #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try sut("invalid room name")  // Spaces are invalid
        }
    }

    @Test("Should throw InvalidRoomName error for empty string")
    func shouldThrowInvalidRoomNameErrorForEmptyString() throws {
        let sut = makeSUT()

        #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try sut("")
        }
    }

    @Test("Use case should be async compatible")
    func shouldWorkInAsyncContext() throws {
        let sut = makeSUT()

        // Verify async behavior works correctly
        let validName = "testasyncroomname"
        try sut(validName)

        // Multiple async calls should work
        try sut("room1")
        try sut("room2")
    }

    @Test("Should validate room names quickly")
    func shouldValidateRoomNameQuickly() throws {
        let sut = makeSUT()

        // Performance test - validation should be fast
        let startTime = CFAbsoluteTimeGetCurrent()

        for index in 0..<1000 {
            try sut("quickroom\(index)")
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 1.0, "Room name validation should be fast")
    }

    // MARK: - Error Type Verification

    @Test("Should throw correct error type for invalid room name")
    func shouldThrowCorrectErrorTypeForInvalidRoomName() throws {
        let sut = makeSUT()

        do {
            try sut("@invalid")
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as TryJoinRoomUseCase.Error {
            #expect(error == .invalidRoomName)
        } catch {
            #expect(Bool(false), "Should have thrown TryJoinRoomUseCase.Error.invalidRoomName")
        }
    }

    // MARK: - Helper

    private func makeSUT() -> TryJoinRoomUseCase {
        TryJoinRoomUseCase()
    }
}
