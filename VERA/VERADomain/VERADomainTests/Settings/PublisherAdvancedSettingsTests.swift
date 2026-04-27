//
//  Created by Vonage on 24/04/2026.
//

import Testing
import VERADomain

@Suite("PublisherAdvancedSettings tests")
struct PublisherAdvancedSettingsTests {

    // MARK: - Init

    @Test("Given no arguments, when initialised, then all properties are nil")
    func initWithNoArgumentsAllPropertiesAreNil() {
        let sut = PublisherAdvancedSettings()

        #expect(sut.videoResolution == nil)
        #expect(sut.videoFrameRate == nil)
        #expect(sut.preferredVideoCodecs == nil)
        #expect(sut.maxAudioBitrate == nil)
        #expect(sut.videoBitratePreset == nil)
        #expect(sut.maxVideoBitrate == nil)
        #expect(sut.publisherAudioFallbackEnabled == nil)
        #expect(sut.subscriberAudioFallbackEnabled == nil)
        #expect(sut.degradationPreference == nil)
    }

    @Test("Given all arguments, when initialised, then all properties are stored correctly")
    func initWithAllArgumentsStoresCorrectValues() {
        let codecPreference = VideoCodecPreference(automatic: false, codecs: [.vp8, .h264])
        let sut = PublisherAdvancedSettings(
            videoResolution: .high,
            videoFrameRate: .rate30FPS,
            preferredVideoCodecs: codecPreference,
            maxAudioBitrate: 64_000,
            videoBitratePreset: .customBitrate,
            maxVideoBitrate: 1_000_000,
            publisherAudioFallbackEnabled: true,
            subscriberAudioFallbackEnabled: false,
            degradationPreference: .maintainResolution
        )

        #expect(sut.videoResolution == .high)
        #expect(sut.videoFrameRate == .rate30FPS)
        #expect(sut.preferredVideoCodecs == codecPreference)
        #expect(sut.maxAudioBitrate == 64_000)
        #expect(sut.videoBitratePreset == .customBitrate)
        #expect(sut.maxVideoBitrate == 1_000_000)
        #expect(sut.publisherAudioFallbackEnabled == true)
        #expect(sut.subscriberAudioFallbackEnabled == false)
        #expect(sut.degradationPreference == .maintainResolution)
    }

    // MARK: - Equatable

    @Test("Given two identical settings, then they are equal")
    func equalSettingsAreEqual() {
        let lhs = PublisherAdvancedSettings(videoResolution: .low, maxAudioBitrate: 48_000)
        let rhs = PublisherAdvancedSettings(videoResolution: .low, maxAudioBitrate: 48_000)

        #expect(lhs == rhs)
    }

    @Test("Given two settings differing by videoResolution, then they are not equal")
    func settingsWithDifferentResolutionAreNotEqual() {
        let lhs = PublisherAdvancedSettings(videoResolution: .low)
        let rhs = PublisherAdvancedSettings(videoResolution: .high)

        #expect(lhs != rhs)
    }

    @Test("Given two settings differing by maxAudioBitrate, then they are not equal")
    func settingsWithDifferentAudioBitrateAreNotEqual() {
        let lhs = PublisherAdvancedSettings(maxAudioBitrate: 32_000)
        let rhs = PublisherAdvancedSettings(maxAudioBitrate: 64_000)

        #expect(lhs != rhs)
    }

    @Test("Given settings with different publisherAudioFallback values, then they are not equal")
    func settingsWithDifferentPublisherAudioFallbackAreNotEqual() {
        let lhs = PublisherAdvancedSettings(publisherAudioFallbackEnabled: true)
        let rhs = PublisherAdvancedSettings(publisherAudioFallbackEnabled: false)

        #expect(lhs != rhs)
    }

    // MARK: - Hashable

    @Test("Given two equal settings, then their hash values are equal")
    func equalSettingsHaveEqualHashValues() {
        let lhs = PublisherAdvancedSettings(videoResolution: .mediun, maxVideoBitrate: 500_000)
        let rhs = PublisherAdvancedSettings(videoResolution: .mediun, maxVideoBitrate: 500_000)

        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test("Given settings instances, then they can be used as Set elements")
    func settingsCanBeUsedInSet() {
        let settings = PublisherAdvancedSettings(videoResolution: .high, maxAudioBitrate: 64_000)
        var set: Set<PublisherAdvancedSettings> = []

        set.insert(settings)
        set.insert(settings)

        #expect(set.count == 1)
    }
}
