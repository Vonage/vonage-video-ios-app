//
//  Created by Vonage on 10/5/26.
//

import Foundation
import Testing

@testable import VERABackgroundEffects

@Suite("AppleVisionSegmentationTransformer tests")
struct AppleVisionSegmentationTransformerTests {

    @Test func initialiseWithFastQualityDoesNotTrap() {
        let sut = AppleVisionSegmentationTransformer(blurRadius: 10, quality: .fast)
        _ = sut
    }

    @Test func initialiseWithBalancedQualityDoesNotTrap() {
        let sut = AppleVisionSegmentationTransformer(blurRadius: 10, quality: .balanced)
        _ = sut
    }

    @Test func initialiseWithAccurateQualityDoesNotTrap() {
        let sut = AppleVisionSegmentationTransformer(blurRadius: 18, quality: .accurate)
        _ = sut
    }

    @Test func zeroBlurRadiusInitialisesCleanly() {
        let sut = AppleVisionSegmentationTransformer(blurRadius: 0, quality: .fast)
        _ = sut
    }
}

@Suite("BlurLevel → Apple Vision blur radius")
struct BlurLevelVisionRadiusTests {

    @Test func noneMapsToZero() {
        #expect(BlurLevel.none.appleVisionBlurRadius == 0)
    }

    @Test func lowProducesSmallerRadiusThanHigh() {
        #expect(BlurLevel.low.appleVisionBlurRadius < BlurLevel.high.appleVisionBlurRadius)
    }

    @Test func lowAndHighAreBothPositive() {
        #expect(BlurLevel.low.appleVisionBlurRadius > 0)
        #expect(BlurLevel.high.appleVisionBlurRadius > 0)
    }
}
