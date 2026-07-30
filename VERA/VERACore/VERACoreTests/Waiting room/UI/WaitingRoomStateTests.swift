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

    // MARK: - allowAudioOutputTest Tests

    @Test("allowAudioOutputTest defaults to false")
    func allowAudioOutputTestDefaultsToFalse() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )

        #expect(state.allowAudioOutputTest == false)
    }

    @Test("allowAudioOutputTest can be set to true")
    func allowAudioOutputTestCanBeSetToTrue() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioOutputTest: true,
            publisher: nil
        )

        #expect(state.allowAudioOutputTest == true)
    }

    @Test("States with different allowAudioOutputTest should not be equal")
    func statesWithDifferentAllowAudioOutputTestShouldNotBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioOutputTest: true,
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioOutputTest: false,
            publisher: nil
        )

        #expect(stateA != stateB)
    }

    @Test("States with same allowAudioOutputTest should be equal")
    func statesWithSameAllowAudioOutputTestShouldBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioOutputTest: true,
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioOutputTest: true,
            publisher: nil
        )

        #expect(stateA == stateB)
    }
}
