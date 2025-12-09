//
//  Created by Vonage on 13/10/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers
import VERAVonage

@testable import VERAVonageCallKitPlugin

@Suite("Vonage Callkit Plugin tests")
struct VonageCallKitPluginTests {

    @Test func notifiesToCallManagerWhenCallStarts() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        try await sut.callDidStart([
            VonageCallParams.roomName.rawValue: "a-room-name",
            VonageCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(
            mockController.recordedActions == [
                .startCall(callID: uuid, handle: "a-room-name", isVideo: true)
            ])
        #expect(sut.currentCallID == uuid)
    }

    @Test func notifiesToCallManagerWhenCallEnds() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        try await sut.callDidStart([
            VonageCallParams.roomName.rawValue: "a-room-name",
            VonageCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(
            mockController.recordedActions == [
                .startCall(callID: uuid, handle: "a-room-name", isVideo: true)
            ])
        #expect(sut.currentCallID == uuid)

        try await sut.callDidEnd()

        #expect(
            mockController.recordedActions == [
                .startCall(callID: uuid, handle: "a-room-name", isVideo: true),
                .endCall(callID: uuid),
            ])
        #expect(sut.currentCallID == nil)
    }

    @Test func whenProviderDelegateEndsCallShouldDisconnect() async {
        let sut = makeSUT()
        let call = MockCall()

        sut.call = call

        #expect(sut.call != nil)

        sut.setup()

        sut.providerDelegate?.onEndCall?()

        await delay()

        /// It can contain more than one disconnect, due to the end call and provider reset
        #expect(call.recordedActions.contains(.disconnect))
    }

    @Test func setupInitializesCallManager() async {
        let sut = makeSUT()

        #expect(sut.callManager == nil)

        sut.setup()

        #expect(sut.callManager != nil)
    }

    @Test func setupInitializesSessionManager() async {
        let sut = makeSUT()

        #expect(sut.sessionManager == nil)

        sut.setup()

        #expect(sut.sessionManager != nil)
    }

    @Test func setupInitializesProviderDelegate() async {
        let sut = makeSUT()

        #expect(sut.providerDelegate == nil)

        sut.setup()

        #expect(sut.providerDelegate != nil)
    }

    @Test(arguments: [true, false])
    func whenProviderDelegateCallsOnHoldShouldSetCallOnHoldState(isOnHold: Bool) async {
        let sut = makeSUT()
        let call = MockCall()
        sut.call = call

        sut.setup()

        sut.providerDelegate?.onHold?(isOnHold)

        #expect(call.isOnHold == isOnHold)
        #expect(call.recordedActions.contains(.setOnHold))
    }

    @Test(arguments: [true, false])
    func whenProviderDelegateCallsOnMuteShouldSetMuteState(isMuted: Bool) async {
        let sut = makeSUT()
        let call = MockCall()
        sut.call = call

        sut.setup()

        sut.providerDelegate?.onMute?(isMuted)

        #expect(call.isMuted == isMuted)
        #expect(call.recordedActions.contains(.muteLocalMedia))
    }

    @Test func whenProviderDelegateResetsProviderShouldDisconnect() async {
        let sut = makeSUT()
        let call = MockCall()
        sut.call = call

        sut.setup()

        sut.providerDelegate?.onProviderReset?()

        await delay()

        #expect(call.recordedActions.contains(.disconnect))
    }

    @Test func callDidStartWithInvalidUUIDShouldThrowError() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        await #expect(throws: VonageCallKitPlugin.Error.invalidCallID) {
            try await sut.callDidStart([
                VonageCallParams.roomName.rawValue: "a-room-name",
                VonageCallParams.callID.rawValue: "invalid-uuid",
            ])
        }

        #expect(mockController.recordedActions.isEmpty)
    }

    @Test func callDidStartWithMissingCallIDShouldThrowError() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        await #expect(throws: VonageCallKitPlugin.Error.invalidCallID) {
            try await sut.callDidStart([
                VonageCallParams.roomName.rawValue: "a-room-name"
            ])
        }

        #expect(mockController.recordedActions.isEmpty)
    }

    @Test func callDidStartWithMissingRoomNameShouldUseEmptyString() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        try await sut.callDidStart([
            VonageCallParams.callID.rawValue: uuid.uuidString
        ])

        #expect(
            mockController.recordedActions == [
                .startCall(callID: uuid, handle: "", isVideo: true)
            ])
    }

    @Test func callDidEndWithoutCurrentCallIDShouldNotCallEndOnCallManager() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        try await sut.callDidEnd()

        #expect(mockController.recordedActions.isEmpty)
    }

    @Test func callDidEndClearsCurrentCallID() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        try await sut.callDidStart([
            VonageCallParams.roomName.rawValue: "a-room-name",
            VonageCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(sut.currentCallID == uuid)

        try await sut.callDidEnd()

        #expect(sut.currentCallID == nil)
    }

    @Test func callDidStartWithCallControllerErrorShouldPropagateError() async throws {
        let mockController = MockCallController()
        let expectedError = NSError(domain: "test", code: -1)
        mockController.errorToReturn = expectedError
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        await #expect(throws: Error.self) {
            try await sut.callDidStart([
                VonageCallParams.roomName.rawValue: "a-room-name",
                VonageCallParams.callID.rawValue: uuid.uuidString,
            ])
        }
    }

    @Test func callDidEndWithCallControllerErrorShouldPropagateError() async throws {
        let mockController = MockCallController()
        let sut = makeSUT(callController: mockController)

        let uuid = UUID()

        try await sut.callDidStart([
            VonageCallParams.roomName.rawValue: "a-room-name",
            VonageCallParams.callID.rawValue: uuid.uuidString,
        ])

        // Configure error after start
        let expectedError = NSError(domain: "test", code: -1)
        mockController.errorToReturn = expectedError

        await #expect(throws: Error.self) {
            try await sut.callDidEnd()
        }
    }

    @Test func providerDelegateCallbacksWithNilCallShouldNotCrash() async {
        let sut = makeSUT()

        #expect(sut.call == nil)

        sut.setup()

        sut.providerDelegate?.onEndCall?()
        await delay()

        sut.providerDelegate?.onProviderReset?()
        await delay()

        sut.providerDelegate?.onHold?(true)
        sut.providerDelegate?.onMute?(true)

        // If reached here, no crash occurred
    }

    @Test func pluginIdentifierReturnsCorrectValue() async {
        let sut = makeSUT()

        #expect(sut.pluginIdentifier == "VonageCallKitPlugin")
    }

    // MARK: SUT

    func makeSUT(callController: MockCallController? = nil) -> VonageCallKitPlugin {
        let plugin = VonageCallKitPlugin()
        if let callController = callController {
            plugin.callManager = VERACallManager(callController: callController)
        }
        return plugin
    }
}

private func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}
