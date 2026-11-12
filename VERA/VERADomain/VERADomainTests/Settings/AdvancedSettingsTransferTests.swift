//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Advanced publisher settings value transfer")
struct AdvancedSettingsTransferTests {

    @Test("Empty and populated settings cross the existing use-case actor boundary")
    func settingsFromActor() async {
        let populated = PublisherAdvancedSettings(
            videoResolution: .high1080p, videoFrameRate: .rate30FPS,
            preferredVideoCodecs: .init(automatic: false, codecs: [.vp9, .h264, .vp8]),
            maxAudioBitrate: 64_000, videoBitratePreset: .customBitrate,
            maxVideoBitrate: 1_000_000, publisherAudioFallbackEnabled: true,
            subscriberAudioFallbackEnabled: false, degradationPreference: .maintainResolution,
            opusDtxEnabled: true)
        for settings in [PublisherAdvancedSettings(), populated] {
            let useCase = SettingsUseCase(settings: settings)
            let received = await useCase()
            #expect(received == settings)
            #expect(received.opusDtxEnabled == settings.opusDtxEnabled)
            #expect(received.preferredVideoCodecs?.codecs == settings.preferredVideoCodecs?.codecs)
        }
    }

    @Test("Automatic, empty and ordered codec preferences survive task transfer")
    func codecPreferencesAcrossTasks() async {
        let preferences = [
            VideoCodecPreference(automatic: true, codecs: nil),
            VideoCodecPreference(automatic: true, codecs: []),
            VideoCodecPreference(automatic: false, codecs: [.vp9, .h264, .vp8]),
        ]
        let received = await Task.detached { preferences }.value
        #expect(received == preferences)
        #expect(received[0].codecs == nil)
        #expect(received[1].codecs == [])
        #expect(received[2].codecs == [.vp9, .h264, .vp8])
    }

    @Test("Individual media preference values can cross task boundaries")
    func mediaPreferencesAcrossTasks() async {
        await verifyTransfer([VideoResolution.low, .mediun, .high, .high1080p])
        await verifyTransfer([VideoFrameRate.rate30FPS, .rate15FPS, .rate7FPS, .rate1FPS])
        await verifyTransfer([VideoBitratePreset.default, .bwSaver, .extraBwSaver, .customBitrate])
        await verifyTransfer([
            DegradationPreference.notSet, .maintainFrameRateAndResolution,
            .maintainFrameRate, .maintainResolution, .balanced,
        ])
        await verifyTransfer([VideoCodecType.vp8, .h264, .vp9])
    }

    private func verifyTransfer<T: Sendable & Equatable>(_ values: [T]) async {
        let received = await Task.detached { values }.value
        #expect(received == values)
    }
}

private actor SettingsUseCase: PublisherAdvancedSettingsUseCase {
    let settings: PublisherAdvancedSettings

    init(settings: PublisherAdvancedSettings) {
        self.settings = settings
    }

    func callAsFunction() async -> PublisherAdvancedSettings {
        settings
    }
}
