//
//  Created by Vonage on 11/5/26.
//

import Foundation
import Testing

@testable import VERABackgroundEffects

@Suite("BackgroundEffectProvider tests")
struct BackgroundEffectProviderTests {

    @Test
    func rawValuesMatchSettingsEnum() {
        // Raw values match VERASettings' SettingsBackgroundProvider so the
        // bridging adapter (`SettingsBackgroundProvider.asBackgroundEffectProvider`)
        // can use `init(rawValue:)` directly.
        #expect(BackgroundEffectProvider.vonage.rawValue == 1)
        #expect(BackgroundEffectProvider.appleVision.rawValue == 2)
    }

    @Test
    func allCasesEnumeratesBoth() {
        #expect(BackgroundEffectProvider.allCases == [.vonage, .appleVision])
    }

    @Test
    func equality() {
        #expect(BackgroundEffectProvider.vonage == .vonage)
        #expect(BackgroundEffectProvider.vonage != .appleVision)
    }
}

@Suite("AppleVisionSegmentationQuality tests")
struct AppleVisionSegmentationQualityTests {

    @Test
    func rawValuesAlignWithVisionQualityLevel() {
        // Raw values match Apple's `VNGeneratePersonSegmentationRequest.QualityLevel`
        // ordering (fast/balanced/accurate = 0/1/2). This lets the transformer
        // bridge with `VNGeneratePersonSegmentationRequest.QualityLevel(rawValue:)`
        // without an explicit switch.
        #expect(AppleVisionSegmentationQuality.fast.rawValue == 0)
        #expect(AppleVisionSegmentationQuality.balanced.rawValue == 1)
        #expect(AppleVisionSegmentationQuality.accurate.rawValue == 2)
    }

    @Test
    func allCasesEnumeratesAllThree() {
        #expect(
            AppleVisionSegmentationQuality.allCases == [.fast, .balanced, .accurate]
        )
    }

    @Test
    func equality() {
        #expect(AppleVisionSegmentationQuality.fast == .fast)
        #expect(AppleVisionSegmentationQuality.fast != .accurate)
    }
}
