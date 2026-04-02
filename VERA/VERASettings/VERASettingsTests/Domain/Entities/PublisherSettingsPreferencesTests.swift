//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("PublisherSettingsPreferences tests")
struct PublisherSettingsPreferencesTests {

    // MARK: - Default Values

    @Test("Default preferences have correct values")
    func defaultPreferences() {
        let prefs = PublisherSettingsPreferences.default

        #expect(prefs.videoResolution == .medium)
        #expect(prefs.videoFrameRate == .fps30)
        #expect(prefs.codecPreference == .automatic)
        #expect(prefs.maxAudioBitrate == 40_000)
        #expect(prefs.videoBitratePreset == .default)
        #expect(prefs.maxVideoBitrate == 500_000)
        #expect(prefs.publisherAudioFallbackEnabled == true)
        #expect(prefs.subscriberAudioFallbackEnabled == true)
        #expect(prefs.senderStatsEnabled == false)
    }

    // MARK: - Equality

    @Test("Two default preferences are equal")
    func defaultPreferencesEquality() {
        let prefs1 = PublisherSettingsPreferences.default
        let prefs2 = PublisherSettingsPreferences.default

        #expect(prefs1 == prefs2)
    }

    @Test("Preferences with different resolution are not equal")
    func preferencesInequalityByResolution() {
        let prefs1 = PublisherSettingsPreferences(videoResolution: .high)
        let prefs2 = PublisherSettingsPreferences(videoResolution: .low)

        #expect(prefs1 != prefs2)
    }

    // MARK: - Encoding / Decoding round-trip

    @Test("Default preferences survive encode-decode round trip")
    func defaultPreferencesRoundTrip() throws {
        let original = PublisherSettingsPreferences.default

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(original == decoded)
    }

    @Test("Custom preferences survive encode-decode round trip")
    func customPreferencesRoundTrip() throws {
        let original = PublisherSettingsPreferences(
            videoResolution: .high,
            videoFrameRate: .fps15,
            codecPreference: SettingsCodecPreference(mode: .manual, orderedCodecs: [.h264, .vp9]),
            maxAudioBitrate: 64_000,
            videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000,
            publisherAudioFallbackEnabled: false,
            subscriberAudioFallbackEnabled: false,
            senderStatsEnabled: true)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(original == decoded)
    }

    // MARK: - Migration from legacy format

    @Test("Decodes legacy audioFallbackEnabled field into both publisher and subscriber fields")
    func decodesLegacyAudioFallbackEnabled() throws {
        let legacyJSON = """
            {
                "videoResolution": 1,
                "videoFrameRate": 30,
                "maxAudioBitrate": 40000,
                "audioFallbackEnabled": false
            }
            """
        let data = legacyJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.publisherAudioFallbackEnabled == false)
        #expect(decoded.subscriberAudioFallbackEnabled == false)
    }

    @Test("Decodes legacy preferredVideoCodec field into codec preference")
    func decodesLegacyPreferredVideoCodec() throws {
        let legacyJSON = """
            {
                "videoResolution": 1,
                "videoFrameRate": 30,
                "maxAudioBitrate": 40000,
                "audioFallbackEnabled": true,
                "preferredVideoCodec": 3
            }
            """
        let data = legacyJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.codecPreference.mode == .manual)
        #expect(decoded.codecPreference.orderedCodecs == [.vp9])
    }

    @Test("Decodes missing codecPreference and preferredVideoCodec as automatic")
    func decodesMissingCodecPreferenceAsAutomatic() throws {
        let json = """
            {
                "videoResolution": 1,
                "videoFrameRate": 30,
                "maxAudioBitrate": 40000,
                "audioFallbackEnabled": true
            }
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.codecPreference == .automatic)
    }

    @Test("Decodes missing videoBitratePreset as default")
    func decodesMissingVideoBitratePresetAsDefault() throws {
        let json = """
            {
                "videoResolution": 1,
                "videoFrameRate": 30,
                "maxAudioBitrate": 40000,
                "audioFallbackEnabled": true
            }
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.videoBitratePreset == .default)
    }

    @Test("Decodes missing senderStatsEnabled as false")
    func decodesMissingSenderStatsAsDisabled() throws {
        let json = """
            {
                "videoResolution": 1,
                "videoFrameRate": 30,
                "maxAudioBitrate": 40000,
                "audioFallbackEnabled": true
            }
            """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.senderStatsEnabled == false)
    }

    // MARK: - Bridge to Domain

    @Test("Bridge converts default preferences to correct domain settings")
    func bridgeDefaultPreferences() {
        let prefs = PublisherSettingsPreferences.default
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.videoResolution == .mediun)
        #expect(advanced.videoFrameRate == .rate30FPS)
        #expect(advanced.preferredVideoCodecs?.automatic == true)
        #expect(advanced.maxAudioBitrate == 40_000)
        #expect(advanced.videoBitratePreset == .default)
        #expect(advanced.maxVideoBitrate == nil)
        #expect(advanced.publisherAudioFallbackEnabled == true)
        #expect(advanced.subscriberAudioFallbackEnabled == true)
    }

    @Test("Bridge converts custom bitrate preset correctly")
    func bridgeCustomBitratePreset() {
        let prefs = PublisherSettingsPreferences(
            videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000)
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.videoBitratePreset == .customBitrate)
        #expect(advanced.maxVideoBitrate == 2_000_000)
    }

    @Test("Bridge does not pass maxVideoBitrate when not custom preset")
    func bridgeNonCustomBitratePreset() {
        let prefs = PublisherSettingsPreferences(
            videoBitratePreset: .bandwidthSaver,
            maxVideoBitrate: 2_000_000)
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.videoBitratePreset == .bwSaver)
        #expect(advanced.maxVideoBitrate == nil)
    }

    @Test("Bridge converts manual codec preference correctly")
    func bridgeManualCodecPreference() {
        let prefs = PublisherSettingsPreferences(
            codecPreference: SettingsCodecPreference(
                mode: .manual,
                orderedCodecs: [.vp9, .h264, .vp8]))
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.preferredVideoCodecs?.automatic == false)
        #expect(advanced.preferredVideoCodecs?.codecs == [.vp9, .h264, .vp8])
    }

    @Test(
        "Bridge converts all video resolution values",
        arguments: [
            (SettingsVideoResolution.low, VideoResolution.low),
            (SettingsVideoResolution.medium, VideoResolution.mediun),
            (SettingsVideoResolution.high, VideoResolution.high),
            (SettingsVideoResolution.high1080p, VideoResolution.high1080p),
        ])
    func bridgeVideoResolution(settingsRes: SettingsVideoResolution, domainRes: VideoResolution) {
        let prefs = PublisherSettingsPreferences(videoResolution: settingsRes)
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.videoResolution == domainRes)
    }

    @Test(
        "Bridge converts all frame rate values",
        arguments: [
            (SettingsVideoFrameRate.fps1, VideoFrameRate.rate1FPS),
            (SettingsVideoFrameRate.fps7, VideoFrameRate.rate7FPS),
            (SettingsVideoFrameRate.fps15, VideoFrameRate.rate15FPS),
            (SettingsVideoFrameRate.fps30, VideoFrameRate.rate30FPS),
        ])
    func bridgeVideoFrameRate(settingsRate: SettingsVideoFrameRate, domainRate: VideoFrameRate) {
        let prefs = PublisherSettingsPreferences(videoFrameRate: settingsRate)
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.videoFrameRate == domainRate)
    }

    @Test(
        "Bridge converts all codec values",
        arguments: [
            (SettingsVideoCodec.vp8, VideoCodecType.vp8),
            (SettingsVideoCodec.h264, VideoCodecType.h264),
            (SettingsVideoCodec.vp9, VideoCodecType.vp9),
        ])
    func bridgeVideoCodec(settingsCodec: SettingsVideoCodec, domainCodec: VideoCodecType) {
        let prefs = PublisherSettingsPreferences(
            codecPreference: SettingsCodecPreference(
                mode: .manual,
                orderedCodecs: [settingsCodec]))
        let advanced = prefs.toPublisherAdvancedSettings()

        #expect(advanced.preferredVideoCodecs?.codecs?.first == domainCodec)
    }
}
