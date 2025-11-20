//
//  Created by Vonage on 13/10/25.
//

import Foundation
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@testable import VERAOpenTokCallKitPlugin

@Suite("OpenTok Callkit Plugin tests")
struct OpenTokCallKitPluginTests {

    @Test func notifiesToCallManagerWhenCallStarts() async throws {
        let sut = makeSUT()

        let uuid = UUID()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        try sut.callDidStart([
            OpenTokCallParams.roomName.rawValue: "a-room-name",
            OpenTokCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(callManagerSpy.recordedActions == [.startCall(.init(handle: "a-room-name", callID: uuid))])
        #expect(sut.currentCallID == uuid)
    }

    @Test func notifiesToCallManagerWhenCallEnds() async throws {
        let sut = makeSUT()

        let uuid = UUID()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        try sut.callDidStart([
            OpenTokCallParams.roomName.rawValue: "a-room-name",
            OpenTokCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(callManagerSpy.recordedActions == [.startCall(.init(handle: "a-room-name", callID: uuid))])
        #expect(sut.currentCallID == uuid)

        sut.callDidEnd()

        #expect(
            callManagerSpy.recordedActions == [
                .startCall(.init(handle: "a-room-name", callID: uuid)),
                .end(.init(callID: uuid)),
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

    @Test func callDidStartWithInvalidUUIDShouldNotStartCall() async throws {
        let sut = makeSUT()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        do {
            try sut.callDidStart([
                OpenTokCallParams.roomName.rawValue: "a-room-name"
            ])
            Issue.record("Expected call id error to be thrown")
        } catch {
            // Should throw an error
        }
    }

    @Test func callDidStartWithMissingRoomNameShouldUseEmptyString() async throws {
        let sut = makeSUT()
        let uuid = UUID()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        try sut.callDidStart([
            OpenTokCallParams.callID.rawValue: uuid.uuidString
        ])

        #expect(callManagerSpy.recordedActions == [.startCall(.init(handle: "", callID: uuid))])
    }

    @Test func callDidEndWithoutCurrentCallIDShouldNotCallEndOnCallManager() async {
        let sut = makeSUT()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        sut.callDidEnd()

        #expect(callManagerSpy.recordedActions.isEmpty)
    }

    @Test func callDidEndClearsCurrentCallID() async throws {
        let sut = makeSUT()
        let uuid = UUID()
        let callManagerSpy = VERACallManagerSpy()
        sut.callManager = callManagerSpy

        try sut.callDidStart([
            OpenTokCallParams.roomName.rawValue: "a-room-name",
            OpenTokCallParams.callID.rawValue: uuid.uuidString,
        ])

        #expect(sut.currentCallID == uuid)

        sut.callDidEnd()

        #expect(sut.currentCallID == nil)
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

        #expect(sut.pluginIdentifier == "OpenTokCallKitPlugin")
    }

    // MARK: SUT

    func makeSUT() -> OpenTokCallKitPlugin {
        OpenTokCallKitPlugin()
    }
}

class VERACallManagerSpy: VERACallManager {
    struct StartCallData: Equatable {
        let handle: String, callID: UUID
    }

    struct EndCallData: Equatable {
        let callID: UUID
    }

    enum Action: Equatable {
        case startCall(StartCallData)
        case end(EndCallData)
    }

    var recordedActions: [Action] = []

    override func startCall(handle: String, callID: UUID) {
        recordedActions.append(.startCall(.init(handle: handle, callID: callID)))
        super.startCall(handle: handle, callID: callID)
    }

    override func end(callID: UUID) {
        recordedActions.append(.end(.init(callID: callID)))
        super.end(callID: callID)
    }
}

private func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}
