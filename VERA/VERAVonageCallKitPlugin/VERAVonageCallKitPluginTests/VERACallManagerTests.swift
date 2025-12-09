//
//  Created by Vonage on 20/11/25.
//

import CallKit
import Foundation
import Testing

@testable import VERAVonageCallKitPlugin

@Suite("VERA Call Manager tests")
struct VERACallManagerTests {

    // MARK: - Helpers

    func makeSUT(callController: MockCallController = MockCallController()) -> (VERACallManager, MockCallController) {
        let sut = VERACallManager(callController: callController)
        return (sut, callController)
    }

    // MARK: - Start Call Tests

    @Test func startCallShouldRequestStartCallTransaction() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()
        let handle = "test-room"

        try await sut.startCall(handle: handle, callID: callID)

        #expect(mockController.requestCallCount == 1)
        #expect(
            mockController.recordedActions == [
                .startCall(callID: callID, handle: handle, isVideo: true)
            ])
    }

    @Test func startCallShouldSetIsVideoToTrue() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()

        try await sut.startCall(handle: "room", callID: callID)

        guard case .startCall(_, _, let isVideo) = mockController.recordedActions.first else {
            Issue.record("Expected startCall action")
            return
        }

        #expect(isVideo == true)
    }

    // MARK: - End Call Tests

    @Test func endCallShouldRequestEndCallTransaction() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()

        try await sut.end(callID: callID)

        #expect(mockController.requestCallCount == 1)
        #expect(mockController.recordedActions == [.endCall(callID: callID)])
    }

    // MARK: - Hold Call Tests

    @Test func setHeldWithTrueShouldRequestHoldCallTransaction() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()

        try await sut.setHeld(callID: callID, onHold: true)

        #expect(mockController.requestCallCount == 1)
        #expect(
            mockController.recordedActions == [
                .setHeld(callID: callID, onHold: true)
            ])
    }

    @Test func setHeldWithFalseShouldRequestUnholdCallTransaction() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()

        try await sut.setHeld(callID: callID, onHold: false)

        #expect(mockController.requestCallCount == 1)
        #expect(
            mockController.recordedActions == [
                .setHeld(callID: callID, onHold: false)
            ])
    }

    // MARK: - Error Handling Tests

    @Test func startCallWithErrorShouldThrow() async {
        let mockController = MockCallController()
        mockController.errorToReturn = NSError(domain: "test", code: -1)
        let (sut, _) = makeSUT(callController: mockController)

        await #expect(throws: Error.self) {
            try await sut.startCall(handle: "room", callID: UUID())
        }

        #expect(mockController.requestCallCount == 1)
    }

    @Test func endCallWithErrorShouldThrow() async {
        let mockController = MockCallController()
        mockController.errorToReturn = NSError(domain: "test", code: -1)
        let (sut, _) = makeSUT(callController: mockController)

        await #expect(throws: Error.self) {
            try await sut.end(callID: UUID())
        }

        #expect(mockController.requestCallCount == 1)
    }

    @Test func setHeldWithErrorShouldThrow() async {
        let mockController = MockCallController()
        mockController.errorToReturn = NSError(domain: "test", code: -1)
        let (sut, _) = makeSUT(callController: mockController)

        await #expect(throws: Error.self) {
            try await sut.setHeld(callID: UUID(), onHold: true)
        }

        #expect(mockController.requestCallCount == 1)
    }

    // MARK: - Multiple Actions Tests

    @Test func multipleCallsShouldRecordAllActions() async throws {
        let (sut, mockController) = makeSUT()
        let callID1 = UUID()
        let callID2 = UUID()

        try await sut.startCall(handle: "room1", callID: callID1)
        try await sut.setHeld(callID: callID1, onHold: true)
        try await sut.end(callID: callID1)
        try await sut.startCall(handle: "room2", callID: callID2)

        #expect(mockController.requestCallCount == 4)
        #expect(mockController.recordedActions.count == 4)
        #expect(mockController.recordedActions[0] == .startCall(callID: callID1, handle: "room1", isVideo: true))
        #expect(mockController.recordedActions[1] == .setHeld(callID: callID1, onHold: true))
        #expect(mockController.recordedActions[2] == .endCall(callID: callID1))
        #expect(mockController.recordedActions[3] == .startCall(callID: callID2, handle: "room2", isVideo: true))
    }

    // MARK: - Handle Format Tests

    @Test func startCallShouldUsePhoneNumberHandleType() async throws {
        let (sut, mockController) = makeSUT()
        let callID = UUID()
        let handle = "my-room"

        try await sut.startCall(handle: handle, callID: callID)

        guard case .startCall(_, let recordedHandle, _) = mockController.recordedActions.first else {
            Issue.record("Expected startCall action")
            return
        }

        #expect(recordedHandle == handle)
    }
}
