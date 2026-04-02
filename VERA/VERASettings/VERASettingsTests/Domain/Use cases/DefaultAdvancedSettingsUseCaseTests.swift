//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@testable import VERASettings

@Suite("DefaultAdvancedSettingsUseCase tests")
struct DefaultAdvancedSettingsUseCaseTests {

    @Test("Returns default advanced settings when repository has defaults")
    func returnsDefaultSettings() async {
        let repository = MockSettingsRepository(initialPreferences: .default)
        let sut = DefaultAdvancedSettingsUseCase(publisherSettingsRepository: repository)

        let result = await sut()

        #expect(result.videoResolution == VideoResolution.mediun)
        #expect(result.videoFrameRate == VideoFrameRate.rate30FPS)
        #expect(result.maxAudioBitrate == 40_000)
    }

    @Test("Returns custom advanced settings from repository")
    func returnsCustomSettings() async {
        let customPreferences = PublisherSettingsPreferences(
            videoResolution: .high,
            videoFrameRate: .fps15,
            codecPreference: .defaultManual,
            maxAudioBitrate: 64_000,
            videoBitratePreset: .bandwidthSaver,
            maxVideoBitrate: 1_000_000,
            publisherAudioFallbackEnabled: false,
            subscriberAudioFallbackEnabled: false)

        let repository = MockSettingsRepository(initialPreferences: customPreferences)
        let sut = DefaultAdvancedSettingsUseCase(publisherSettingsRepository: repository)

        let result = await sut()

        #expect(result.videoResolution == VideoResolution.high)
        #expect(result.videoFrameRate == VideoFrameRate.rate15FPS)
        #expect(result.maxAudioBitrate == 64_000)
        #expect(result.publisherAudioFallbackEnabled == false)
        #expect(result.subscriberAudioFallbackEnabled == false)
    }

    @Test("Returns custom bitrate when preset is custom")
    func returnsCustomBitrateWhenPresetIsCustom() async {
        let customPreferences = PublisherSettingsPreferences(
            videoBitratePreset: .custom,
            maxVideoBitrate: 2_000_000)

        let repository = MockSettingsRepository(initialPreferences: customPreferences)
        let sut = DefaultAdvancedSettingsUseCase(publisherSettingsRepository: repository)

        let result = await sut()

        #expect(result.videoBitratePreset == VideoBitratePreset.customBitrate)
        #expect(result.maxVideoBitrate == 2_000_000)
    }

    @Test("Does not return custom bitrate when preset is not custom")
    func doesNotReturnCustomBitrateWhenPresetIsNotCustom() async {
        let preferences = PublisherSettingsPreferences(
            videoBitratePreset: .default,
            maxVideoBitrate: 2_000_000)

        let repository = MockSettingsRepository(initialPreferences: preferences)
        let sut = DefaultAdvancedSettingsUseCase(publisherSettingsRepository: repository)

        let result = await sut()

        #expect(result.videoBitratePreset == VideoBitratePreset.default)
        #expect(result.maxVideoBitrate == nil)
    }
}
