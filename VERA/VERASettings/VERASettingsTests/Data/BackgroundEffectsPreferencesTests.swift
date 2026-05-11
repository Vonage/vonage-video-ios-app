//
//  Created by Vonage on 10/5/26.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("Background effects preferences")
struct BackgroundEffectsPreferencesTests {

    // MARK: - Defaults

    @Test("Default backgroundProvider is .vonage to preserve existing behaviour")
    func defaultsToVonage() {
        let prefs = PublisherSettingsPreferences.default
        #expect(prefs.backgroundProvider == .vonage)
    }

    @Test("Default appleVisionQuality is .fast")
    func defaultsToFastQuality() {
        let prefs = PublisherSettingsPreferences.default
        #expect(prefs.appleVisionQuality == .fast)
    }

    // MARK: - Round-trip

    @Test("Encoding then decoding preserves backgroundProvider and appleVisionQuality")
    func roundTripsThroughCodable() throws {
        let original = PublisherSettingsPreferences(
            backgroundProvider: .appleVision,
            appleVisionQuality: .accurate
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)

        #expect(decoded.backgroundProvider == .appleVision)
        #expect(decoded.appleVisionQuality == .accurate)
        #expect(decoded == original)
    }

    // MARK: - Migration safety

    @Test("Decoding a payload without the new fields yields default values")
    func legacyPayloadDecodesWithDefaults() throws {
        // Synthesised payload representing a pre-Apple-Vision Settings blob.
        let legacyJSON = """
            {
              "videoResolution": 1,
              "videoFrameRate": 30,
              "codecPreference": { "mode": "automatic", "orderedCodecs": [] },
              "maxAudioBitrate": 40000,
              "videoBitratePreset": 0,
              "maxVideoBitrate": 500000,
              "publisherAudioFallbackEnabled": true,
              "subscriberAudioFallbackEnabled": true,
              "senderStatsEnabled": false
            }
            """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: legacyJSON)

        #expect(decoded.backgroundProvider == .vonage)
        #expect(decoded.appleVisionQuality == .fast)
    }

    // MARK: - Equality

    @Test("Preferences differing only in backgroundProvider are not equal")
    func equalityConsidersBackgroundProvider() {
        let lhs = PublisherSettingsPreferences(backgroundProvider: .vonage)
        let rhs = PublisherSettingsPreferences(backgroundProvider: .appleVision)
        #expect(lhs != rhs)
    }

    @Test("Preferences differing only in appleVisionQuality are not equal")
    func equalityConsidersAppleVisionQuality() {
        let lhs = PublisherSettingsPreferences(appleVisionQuality: .fast)
        let rhs = PublisherSettingsPreferences(appleVisionQuality: .balanced)
        #expect(lhs != rhs)
    }
}
