//
//  Created by Vonage on 24/04/2026.
//

import Foundation
import Testing

@testable import VERAMeetingRoom

@Suite("MeetingRoomActions Constructor Tests")
struct MeetingRoomActionsTests {

    // MARK: - Individual Closure Tests

    @Test("onShare closure is called with correct parameter")
    func onShareCallbackWorks() {
        var capturedString: String?
        let actions = MeetingRoomActions(
            onShare: { capturedString = $0 }
        )

        actions.onShare("testValue")
        #expect(capturedString == "testValue")
    }

    @Test("onRetry closure is called")
    func onRetryCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onRetry: { wasCalled = true }
        )

        actions.onRetry()
        #expect(wasCalled)
    }

    @Test("onToggleMic closure is called")
    func onToggleMicCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onToggleMic: { wasCalled = true }
        )

        actions.onToggleMic()
        #expect(wasCalled)
    }

    @Test("onToggleCamera closure is called")
    func onToggleCameraCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onToggleCamera: { wasCalled = true }
        )

        actions.onToggleCamera()
        #expect(wasCalled)
    }

    @Test("onCameraSwitch closure is called")
    func onCameraSwitchCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onCameraSwitch: { wasCalled = true }
        )

        actions.onCameraSwitch()
        #expect(wasCalled)
    }

    @Test("onEndCall closure is called")
    func onEndCallCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onEndCall: { wasCalled = true }
        )

        actions.onEndCall()
        #expect(wasCalled)
    }

    @Test("onToggleParticipants closure is called")
    func onToggleParticipantsCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onToggleParticipants: { wasCalled = true }
        )

        actions.onToggleParticipants()
        #expect(wasCalled)
    }

    @Test("onToggleLayout closure is called")
    func onToggleLayoutCallbackWorks() {
        var wasCalled = false
        let actions = MeetingRoomActions(
            onToggleLayout: { wasCalled = true }
        )

        actions.onToggleLayout()
        #expect(wasCalled)
    }

    // MARK: - Call Count Test

    @Test("Closures can be called multiple times")
    func closuresCanBeCalledMultipleTimes() {
        var callCount = 0
        let actions = MeetingRoomActions(
            onToggleMic: { callCount += 1 }
        )

        actions.onToggleMic()
        #expect(callCount == 1)

        actions.onToggleMic()
        #expect(callCount == 2)

        actions.onToggleMic()
        #expect(callCount == 3)
    }
}
