//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERAConfiguration

@Suite("App configuration value transfer")
struct AppConfigTransferTests {

    @Test("Generated defaults and static settings retain their values across tasks and an actor")
    func defaultConfiguration() async {
        let defaults = AppConfig()
        let received = await transfer(defaults)
        expectSnapshot(received, matches: defaults)
        #expect(received.videoSettings.defaultResolution == "640x480")
        #expect(received.authSettings.idProviders == ["okta"])
        #expect(!received.authSettings.allowAuthentication)
        #expect(received.meetingRoomSettings.defaultLayoutMode == .activeSpeaker)

        let staticDefaults = AppConfig(
            videoSettings: await transfer(AppConfig.videoSettings),
            audioSettings: await transfer(AppConfig.audioSettings),
            authSettings: await transfer(AppConfig.authSettings),
            waitingRoomSettings: await transfer(AppConfig.waitingRoomSettings),
            meetingRoomSettings: await transfer(AppConfig.meetingRoomSettings)
        )
        expectSnapshot(staticDefaults, matches: defaults)
    }

    @Test("Custom settings preserve every field across task and actor boundaries", arguments: [false, true])
    func customConfiguration(enabled: Bool) async {
        let video = AppConfig.VideoSettings(
            allowBackgroundEffects: enabled,
            allowCameraControl: !enabled,
            allowVideoOnJoin: enabled,
            defaultResolution: enabled ? "解像度-🎥" : ""
        )
        let audio = AppConfig.AudioSettings(
            allowAdvancedNoiseSuppression: !enabled,
            allowAudioOnJoin: enabled,
            allowMicrophoneControl: !enabled,
            allowAudioDiagnostics: enabled
        )
        let auth = AppConfig.AuthSettings(
            allowAuthentication: enabled,
            idProviders: enabled ? ["", "認証-α", "provider", "認証-α"] : []
        )
        let waiting = AppConfig.WaitingRoomSettings(
            allowDeviceSelection: !enabled,
            allowSettings: enabled
        )
        let meeting = AppConfig.MeetingRoomSettings(
            allowArchiving: enabled,
            allowCaptions: !enabled,
            allowCaptionTranslation: enabled,
            allowChat: enabled,
            allowDeviceSelection: !enabled,
            allowEmojis: enabled,
            allowFeedback: !enabled,
            allowPictureInPicture: enabled,
            allowScreenShare: !enabled,
            defaultLayoutMode: enabled ? .grid : .activeSpeaker,
            showParticipantList: enabled,
            allowSettings: !enabled
        )
        let expected = AppConfig(
            videoSettings: video,
            audioSettings: audio,
            authSettings: auth,
            waitingRoomSettings: waiting,
            meetingRoomSettings: meeting
        )
        let nestedTransfers = AppConfig(
            videoSettings: await transfer(video),
            audioSettings: await transfer(audio),
            authSettings: await transfer(auth),
            waitingRoomSettings: await transfer(waiting),
            meetingRoomSettings: await transfer(meeting)
        )
        expectSnapshot(nestedTransfers, matches: expected)
        let received = await transfer(expected)
        expectSnapshot(received, matches: expected)
    }

    private func expectSnapshot(_ received: AppConfig, matches expected: AppConfig) {
        #expect(received.videoSettings.allowBackgroundEffects == expected.videoSettings.allowBackgroundEffects)
        #expect(received.videoSettings.allowCameraControl == expected.videoSettings.allowCameraControl)
        #expect(received.videoSettings.allowVideoOnJoin == expected.videoSettings.allowVideoOnJoin)
        #expect(received.videoSettings.defaultResolution == expected.videoSettings.defaultResolution)
        #expect(
            received.audioSettings.allowAdvancedNoiseSuppression == expected.audioSettings.allowAdvancedNoiseSuppression
        )
        #expect(received.audioSettings.allowAudioOnJoin == expected.audioSettings.allowAudioOnJoin)
        #expect(received.audioSettings.allowMicrophoneControl == expected.audioSettings.allowMicrophoneControl)
        #expect(received.audioSettings.allowAudioDiagnostics == expected.audioSettings.allowAudioDiagnostics)
        #expect(received.authSettings.allowAuthentication == expected.authSettings.allowAuthentication)
        #expect(received.authSettings.idProviders == expected.authSettings.idProviders)
        #expect(received.waitingRoomSettings.allowDeviceSelection == expected.waitingRoomSettings.allowDeviceSelection)
        #expect(received.waitingRoomSettings.allowSettings == expected.waitingRoomSettings.allowSettings)
        #expect(received.meetingRoomSettings.allowArchiving == expected.meetingRoomSettings.allowArchiving)
        #expect(received.meetingRoomSettings.allowCaptions == expected.meetingRoomSettings.allowCaptions)
        #expect(
            received.meetingRoomSettings.allowCaptionTranslation
                == expected.meetingRoomSettings.allowCaptionTranslation)
        #expect(received.meetingRoomSettings.allowChat == expected.meetingRoomSettings.allowChat)
        #expect(received.meetingRoomSettings.allowDeviceSelection == expected.meetingRoomSettings.allowDeviceSelection)
        #expect(received.meetingRoomSettings.allowEmojis == expected.meetingRoomSettings.allowEmojis)
        #expect(received.meetingRoomSettings.allowFeedback == expected.meetingRoomSettings.allowFeedback)
        #expect(
            received.meetingRoomSettings.allowPictureInPicture == expected.meetingRoomSettings.allowPictureInPicture)
        #expect(received.meetingRoomSettings.allowScreenShare == expected.meetingRoomSettings.allowScreenShare)
        #expect(received.meetingRoomSettings.defaultLayoutMode == expected.meetingRoomSettings.defaultLayoutMode)
        #expect(received.meetingRoomSettings.showParticipantList == expected.meetingRoomSettings.showParticipantList)
        #expect(received.meetingRoomSettings.allowSettings == expected.meetingRoomSettings.allowSettings)
    }
}

private func transfer<Value: Sendable>(_ value: Value) async -> Value {
    let received = await Task.detached { value }.value
    let store = ConfigurationSnapshot(value: received)
    return await store.read()
}

private actor ConfigurationSnapshot<Value: Sendable> {
    private let value: Value

    init(value: Value) {
        self.value = value
    }

    func read() -> Value {
        value
    }
}
