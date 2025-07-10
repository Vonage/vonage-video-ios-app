//
//  Created by Vonage on 9/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Try join room use case tests")
struct TryJoinRoomUseCaseTests {

    // MARK: - Use Case Behavior Tests (not validation logic)

    @Test("Should succeed with valid room name")
    func shouldSucceedWithValidRoomName() async throws {
        let sut = makeSUT()

        // Test that the use case doesn't throw for a known valid name
        try await sut.invoke("validroom123")
    }

    @Test("Should throw InvalidRoomName error for invalid room name")
    func shouldThrowInvalidRoomNameErrorForInvalidInput() async throws {
        let sut = makeSUT()

        // Test that the use case throws the correct error type
        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("invalid room name")  // Spaces are invalid
        }
    }

    @Test("Should throw InvalidRoomName error for empty string")
    func shouldThrowInvalidRoomNameErrorForEmptyString() async throws {
        let sut = makeSUT()

        await #expect(throws: TryJoinRoomUseCase.Error.invalidRoomName) {
            try await sut.invoke("")
        }
    }

    @Test("Use case should be async compatible")
    func shouldWorkInAsyncContext() async throws {
        let sut = makeSUT()

        // Verify async behavior works correctly
        let validName = "testasyncroomname"
        try await sut.invoke(validName)

        // Multiple async calls should work
        try await sut.invoke("room1")
        try await sut.invoke("room2")
    }

    @Test("Should validate room names quickly")
    func shouldValidateRoomNameQuickly() async throws {
        let sut = makeSUT()

        // Performance test - validation should be fast
        let startTime = CFAbsoluteTimeGetCurrent()

        for index in 0..<1000 {
            try await sut.invoke("quickroom\(index)")
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        #expect(timeElapsed < 1.0, "Room name validation should be fast")
    }

    // MARK: - Error Type Verification

    @Test("Should throw correct error type for invalid room name")
    func shouldThrowCorrectErrorTypeForInvalidRoomName() async throws {
        let sut = makeSUT()

        do {
            try await sut.invoke("@invalid")
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
