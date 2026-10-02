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

    // MARK: - allowSettings Tests

    @Test("allowSettings defaults to false")
    func allowSettingsDefaultsToFalse() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )

        #expect(state.allowSettings == false)
    }

    @Test("allowSettings can be set to true")
    func allowSettingsCanBeSetToTrue() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowSettings: true,
            publisher: nil
        )

        #expect(state.allowSettings == true)
    }

    @Test("States with different allowSettings should not be equal")
    func statesWithDifferentAllowSettingsShouldNotBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowSettings: true,
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowSettings: false,
            publisher: nil
        )

        #expect(stateA != stateB)
    }

    // MARK: - allowBackgroundEffects Tests

    @Test("allowBackgroundEffects defaults to false")
    func allowBackgroundEffectsDefaultsToFalse() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )

        #expect(state.allowBackgroundEffects == false)
    }

    @Test("allowBackgroundEffects can be set to true")
    func allowBackgroundEffectsCanBeSetToTrue() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowBackgroundEffects: true,
            publisher: nil
        )

        #expect(state.allowBackgroundEffects == true)
    }

    @Test("States with different allowBackgroundEffects should not be equal")
    func statesWithDifferentAllowBackgroundEffectsShouldNotBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowBackgroundEffects: true,
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowBackgroundEffects: false,
            publisher: nil
        )

        #expect(stateA != stateB)
    }

    // MARK: - allowAudioEffects Tests

    @Test("allowAudioEffects defaults to false")
    func allowAudioEffectsDefaultsToFalse() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            publisher: nil
        )

        #expect(state.allowAudioEffects == false)
    }

    @Test("allowAudioEffects can be set to true")
    func allowAudioEffectsCanBeSetToTrue() {
        let state = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioEffects: true,
            publisher: nil
        )

        #expect(state.allowAudioEffects == true)
    }

    @Test("States with different allowAudioEffects should not be equal")
    func statesWithDifferentAllowAudioEffectsShouldNotBeEqual() {
        let stateA = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioEffects: true,
            publisher: nil
        )
        let stateB = WaitingRoomState(
            roomName: "room",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [],
            allowAudioEffects: false,
            publisher: nil
        )

        #expect(stateA != stateB)
    }
}
