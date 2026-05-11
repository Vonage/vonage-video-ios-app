//
//  Created by Vonage on 11/5/26.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("SettingsAppleVisionQuality tests")
struct SettingsAppleVisionQualityTests {

    @Test
    func rawValuesMatchDomainEnum() {
        // Raw values align with VERABackgroundEffects' AppleVisionSegmentationQuality
        // and with `VNGeneratePersonSegmentationRequest.QualityLevel` ordering
        // (fast/balanced/accurate = 0/1/2).
        #expect(SettingsAppleVisionQuality.fast.rawValue == 0)
        #expect(SettingsAppleVisionQuality.balanced.rawValue == 1)
        #expect(SettingsAppleVisionQuality.accurate.rawValue == 2)
    }

    @Test
    func allCasesEnumeratesAllThree() {
        #expect(SettingsAppleVisionQuality.allCases == [.fast, .balanced, .accurate])
    }

    @Test
    func idEqualsRawValue() {
        for value in SettingsAppleVisionQuality.allCases {
            #expect(value.id == value.rawValue)
        }
    }

    @Test(arguments: [
        (SettingsAppleVisionQuality.fast, "Fast"),
        (SettingsAppleVisionQuality.balanced, "Balanced"),
        (SettingsAppleVisionQuality.accurate, "Accurate"),
    ])
    func displayNameForEachCase(value: SettingsAppleVisionQuality, expected: String) {
        #expect(value.displayName == expected)
    }

    @Test
    func codableRoundTrip() throws {
        let original = SettingsAppleVisionQuality.balanced
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SettingsAppleVisionQuality.self, from: encoded)
        #expect(decoded == original)
    }
}
