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

        sut.callDidStart([
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

        sut.callDidStart([
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

        #expect(call.recordedActions == [.disconnect])
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
