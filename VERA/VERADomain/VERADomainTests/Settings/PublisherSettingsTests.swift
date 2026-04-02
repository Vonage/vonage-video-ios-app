//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Publisher Settings tests")
struct PublisherSettingsTests {

    // MARK: - PublisherSettings

    @Test("PublisherSettings defaults are correct")
    func publisherSettingsDefaults() {
        let settings = PublisherSettings()

        #expect(settings.username == "")
        #expect(settings.publishAudio == true)
        #expect(settings.publishVideo == true)
        #expect(settings.scaleBehavior == .fill)
        #expect(settings.advancedSettings == nil)
    }

    @Test("PublisherSettings custom values")
    func publisherSettingsCustomValues() {
        let advanced = PublisherAdvancedSettings(videoResolution: .high)
        let settings = PublisherSettings(
            username: "Alice",
            publishAudio: false,
            publishVideo: true,
            scaleBehavior: .fit,
            advancedSettings: advanced)

        #expect(settings.username == "Alice")
        #expect(settings.publishAudio == false)
        #expect(settings.publishVideo == true)
        #expect(settings.scaleBehavior == .fit)
        #expect(settings.advancedSettings != nil)
        #expect(settings.advancedSettings?.videoResolution == .high)
    }

    @Test("PublisherSettings equality")
    func publisherSettingsEquality() {
        let settings1 = PublisherSettings(username: "Bob", publishAudio: true, publishVideo: false)
        let settings2 = PublisherSettings(username: "Bob", publishAudio: true, publishVideo: false)

        #expect(settings1 == settings2)
    }

    @Test("PublisherSettings inequality by username")
    func publisherSettingsInequalityByUsername() {
        let settings1 = PublisherSettings(username: "Alice")
        let settings2 = PublisherSettings(username: "Bob")

        #expect(settings1 != settings2)
    }

    // MARK: - VideoScaleBehavior

    @Test("VideoScaleBehavior raw values")
    func videoScaleBehaviorRawValues() {
        #expect(VideoScaleBehavior.fill.rawValue == "fill")
        #expect(VideoScaleBehavior.fit.rawValue == "fit")
    }

    @Test("VideoScaleBehavior equality")
    func videoScaleBehaviorEquality() {
        #expect(VideoScaleBehavior.fill == VideoScaleBehavior.fill)
        #expect(VideoScaleBehavior.fit == VideoScaleBehavior.fit)
        #expect(VideoScaleBehavior.fill != VideoScaleBehavior.fit)
    }

    // MARK: - PublisherAdvancedSettings

    @Test("PublisherAdvancedSettings defaults are nil")
    func advancedSettingsDefaults() {
        let settings = PublisherAdvancedSettings()

        #expect(settings.videoResolution == nil)
        #expect(settings.videoFrameRate == nil)
        #expect(settings.preferredVideoCodecs == nil)
        #expect(settings.maxAudioBitrate == nil)
        #expect(settings.videoBitratePreset == nil)
        #expect(settings.maxVideoBitrate == nil)
        #expect(settings.publisherAudioFallbackEnabled == nil)
        #expect(settings.subscriberAudioFallbackEnabled == nil)
    }

    @Test("PublisherAdvancedSettings with all values set")
    func advancedSettingsWithAllValues() {
        let codecPref = VideoCodecPreference(automatic: false, codecs: [.vp9, .h264])
        let settings = PublisherAdvancedSettings(
            videoResolution: .high1080p,
            videoFrameRate: .rate30FPS,
            preferredVideoCodecs: codecPref,
            maxAudioBitrate: 64000,
            videoBitratePreset: .customBitrate,
            maxVideoBitrate: 2_000_000,
            publisherAudioFallbackEnabled: true,
            subscriberAudioFallbackEnabled: false)

        #expect(settings.videoResolution == .high1080p)
        #expect(settings.videoFrameRate == .rate30FPS)
        #expect(settings.preferredVideoCodecs == codecPref)
        #expect(settings.maxAudioBitrate == 64000)
        #expect(settings.videoBitratePreset == .customBitrate)
        #expect(settings.maxVideoBitrate == 2_000_000)
        #expect(settings.publisherAudioFallbackEnabled == true)
        #expect(settings.subscriberAudioFallbackEnabled == false)
    }

    @Test("PublisherAdvancedSettings equality")
    func advancedSettingsEquality() {
        let settings1 = PublisherAdvancedSettings(videoResolution: .high, videoFrameRate: .rate15FPS)
        let settings2 = PublisherAdvancedSettings(videoResolution: .high, videoFrameRate: .rate15FPS)

        #expect(settings1 == settings2)
    }

    @Test("PublisherAdvancedSettings inequality")
    func advancedSettingsInequality() {
        let settings1 = PublisherAdvancedSettings(videoResolution: .high)
        let settings2 = PublisherAdvancedSettings(videoResolution: .low)

        #expect(settings1 != settings2)
    }

    // MARK: - VideoCodecPreference

    @Test("VideoCodecPreference automatic mode")
    func videoCodecPreferenceAutomatic() {
        let pref = VideoCodecPreference(automatic: true, codecs: nil)

        #expect(pref.automatic == true)
        #expect(pref.codecs == nil)
    }

    @Test("VideoCodecPreference manual mode with codecs")
    func videoCodecPreferenceManual() {
        let pref = VideoCodecPreference(automatic: false, codecs: [.vp9, .vp8, .h264])

        #expect(pref.automatic == false)
        #expect(pref.codecs == [.vp9, .vp8, .h264])
    }

    @Test("VideoCodecPreference equality")
    func videoCodecPreferenceEquality() {
        let pref1 = VideoCodecPreference(automatic: true, codecs: [.vp8])
        let pref2 = VideoCodecPreference(automatic: true, codecs: [.vp8])

        #expect(pref1 == pref2)
    }

    @Test("VideoCodecPreference inequality by automatic flag")
    func videoCodecPreferenceInequalityByFlag() {
        let pref1 = VideoCodecPreference(automatic: true, codecs: [.vp8])
        let pref2 = VideoCodecPreference(automatic: false, codecs: [.vp8])

        #expect(pref1 != pref2)
    }
}
