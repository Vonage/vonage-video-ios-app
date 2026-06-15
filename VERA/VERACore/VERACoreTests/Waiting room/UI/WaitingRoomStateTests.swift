//
//  Created by Vonage on 1/6/26.
//

import Testing
import VERATestHelpers

@testable import VERACore

@Suite("WaitingRoomState equality tests")
struct WaitingRoomStateTests {

    @Test("States with different publishers should not be equal")
    func statesWithDifferentPublishersShouldNotBeEqual() {
        let publisherA = MockVERAPublisher()
        let publisherB = MockVERAPublisher()

        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: publisherA
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: publisherB
        )

        #expect(stateA != stateB)
    }

    @Test("States with same publisher should be equal")
    func statesWithSamePublisherShouldBeEqual() {
        let publisher = MockVERAPublisher()

        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: publisher
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: publisher
        )

        #expect(stateA == stateB)
    }

    @Test("States with nil publishers should be equal")
    func statesWithNilPublishersShouldBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )

        #expect(stateA == stateB)
    }
}
