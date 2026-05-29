//
//  Created by Vonage on 28/5/26.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomPublisherSettings conversion tests")
struct MeetingRoomPublisherSettingsTests {

    @Test("Default settings convert correctly")
    func defaultSettingsConvert() {
        let settings = MeetingRoomPublisherSettings()
        let internal_ = settings.toInternal()

        #expect(internal_.username == "")
        #expect(internal_.publishAudio == true)
        #expect(internal_.publishVideo == true)
        #expect(internal_.scaleBehavior == .fill)
        #expect(internal_.advancedSettings == nil)
        #expect(internal_.initialVideoEffect == nil)
        #expect(internal_.noiseSuppressionState == nil)
    }

    @Test("Custom settings convert correctly")
    func customSettingsConvert() {
        let settings = MeetingRoomPublisherSettings(
            username: "Alice",
            publishAudio: false,
            publishVideo: false,
            scaleBehavior: .fit,
            noiseSuppressionState: .enabled
        )
        let internal_ = settings.toInternal()

        #expect(internal_.username == "Alice")
        #expect(internal_.publishAudio == false)
        #expect(internal_.publishVideo == false)
        #expect(internal_.scaleBehavior == .fit)
        #expect(internal_.noiseSuppressionState == .enabled)
    }

    @Test("Video effect conversions")
    func videoEffectConversions() {
        #expect(MeetingRoomVideoEffect.none.toInternal() == .none)
        #expect(MeetingRoomVideoEffect.blurLow.toInternal() == .blurLow)
        #expect(MeetingRoomVideoEffect.blurHigh.toInternal() == .blurHigh)
        #expect(
            MeetingRoomVideoEffect.backgroundImage(id: "bg1", imagePath: "/path").toInternal()
                == .backgroundImage(id: "bg1", imagePath: "/path")
        )
    }

    @Test("Advanced settings convert correctly")
    func advancedSettingsConvert() {
        let advanced = MeetingRoomPublisherAdvancedSettings(
            videoResolution: .high,
            videoFrameRate: .rate30FPS,
            preferredVideoCodecs: MeetingRoomVideoCodecPreference(
                automatic: false, codecs: [.h264, .vp8]
            ),
            maxAudioBitrate: 128_000,
            videoBitratePreset: .bwSaver,
            maxVideoBitrate: 2_000_000,
            publisherAudioFallbackEnabled: true,
            subscriberAudioFallbackEnabled: false,
            degradationPreference: .balanced,
            opusDtxEnabled: true
        )
        let internal_ = advanced.toInternal()

        #expect(internal_.videoResolution == .high)
        #expect(internal_.videoFrameRate == .rate30FPS)
        #expect(internal_.preferredVideoCodecs?.automatic == false)
        #expect(internal_.preferredVideoCodecs?.codecs == [.h264, .vp8])
        #expect(internal_.maxAudioBitrate == 128_000)
        #expect(internal_.videoBitratePreset == .bwSaver)
        #expect(internal_.maxVideoBitrate == 2_000_000)
        #expect(internal_.publisherAudioFallbackEnabled == true)
        #expect(internal_.subscriberAudioFallbackEnabled == false)
        #expect(internal_.degradationPreference == .balanced)
        #expect(internal_.opusDtxEnabled == true)
    }

    @Test("VideoResolution medium maps to internal mediun typo")
    func videoResolutionMediumMapsCorrectly() {
        #expect(MeetingRoomVideoResolution.medium.toInternal() == .mediun)
    }

    @Test("Fluent builder methods work correctly")
    func fluentMethods() {
        let settings = MeetingRoomPublisherSettings()
            .username("Bob")
            .publishAudio(false)
            .publishVideo(false)
            .scaleBehavior(.fit)

        #expect(settings.username == "Bob")
        #expect(settings.publishAudio == false)
        #expect(settings.publishVideo == false)
        #expect(settings.scaleBehavior == .fit)
    }

    @Test("Noise suppression state conversions")
    func noiseSuppressionConversions() {
        #expect(MeetingRoomNoiseSuppressionState.enabled.toInternal() == .enabled)
        #expect(MeetingRoomNoiseSuppressionState.disabled.toInternal() == .disabled)
        #expect(MeetingRoomNoiseSuppressionState.idle.toInternal() == .idle)
    }
}

@Suite("MeetingRoomConfiguration conversion tests")
struct MeetingRoomConfigurationConversionTests {

    @Test("Default configuration converts correctly")
    func defaultConfigConvert() {
        let config = VERAMeetingRoomSDK.MeetingRoomConfiguration()
        let internal_ = config.toInternal()

        #expect(internal_.allowMicrophoneControl == true)
        #expect(internal_.allowCameraControl == true)
        #expect(internal_.showParticipantList == true)
    }

    @Test("Custom configuration converts correctly")
    func customConfigConvert() {
        let config = VERAMeetingRoomSDK.MeetingRoomConfiguration(
            allowMicrophoneControl: false,
            allowCameraControl: false,
            showParticipantList: false
        )
        let internal_ = config.toInternal()

        #expect(internal_.allowMicrophoneControl == false)
        #expect(internal_.allowCameraControl == false)
        #expect(internal_.showParticipantList == false)
    }
}

@Suite("MeetingRoomTheme conversion tests")
struct MeetingRoomThemeConversionTests {

    @Test("Vonage default theme converts without crashing")
    func vonageThemeConverts() {
        let theme = VERAMeetingRoomSDK.MeetingRoomTheme.vonage
        let internal_ = theme.toInternal()
        // Verify a sampling of properties propagated
        #expect(internal_.primary == theme.primary)
        #expect(internal_.error == theme.error)
    }

    @Test("Custom theme colors propagate")
    func customThemeConverts() {
        var theme = VERAMeetingRoomSDK.MeetingRoomTheme.vonage
        theme.primary = .red
        let internal_ = theme.toInternal()
        #expect(internal_.primary == .red)
    }
}

@Suite("MeetingRoomSessionKeyHolder tests")
struct MeetingRoomSessionKeyHolderTests {

    @Test("DefaultMeetingRoomSessionKeyHolder stores and retrieves key")
    func defaultHolderWorks() {
        let holder = DefaultMeetingRoomSessionKeyHolder()
        #expect(holder.sessionKey == "")

        holder.setSessionKey("jwt-token-123")
        #expect(holder.sessionKey == "jwt-token-123")
    }

    @Test("SessionKeyHolderAdapter bridges correctly")
    func adapterBridges() {
        let holder = DefaultMeetingRoomSessionKeyHolder()
        holder.setSessionKey("test-key")

        let adapter = SessionKeyHolderAdapter(holder: holder)
        #expect(adapter.sessionKey == "test-key")

        adapter.setSessionKey("new-key")
        #expect(holder.sessionKey == "new-key")
    }
}
