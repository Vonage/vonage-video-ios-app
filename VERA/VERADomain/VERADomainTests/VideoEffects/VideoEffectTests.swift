//
//  Created by Vonage on 18/05/2026.
//

import Foundation
import Testing
import VERADomain

@Suite("VideoEffect Tests")
struct VideoEffectTests {

    // MARK: - Cases

    @Test("none case exists")
    func noneCaseExists() {
        let effect = VideoEffect.none
        #expect(effect == .none)
    }

    @Test("blurLow case exists")
    func blurLowCaseExists() {
        let effect = VideoEffect.blurLow
        #expect(effect == .blurLow)
    }

    @Test("blurHigh case exists")
    func blurHighCaseExists() {
        let effect = VideoEffect.blurHigh
        #expect(effect == .blurHigh)
    }

    @Test("backgroundImage case carries id and imagePath")
    func backgroundImageCaseCarriesIdAndImagePath() {
        let effect = VideoEffect.backgroundImage(id: "library", imagePath: "/path/library.jpg")
        #expect(effect == .backgroundImage(id: "library", imagePath: "/path/library.jpg"))
    }

    // MARK: - blurLevel helper

    @Test("blurLow returns BlurLevel.low")
    func blurLowReturnsBlurLevelLow() {
        #expect(VideoEffect.blurLow.blurLevel == .low)
    }

    @Test("blurHigh returns BlurLevel.high")
    func blurHighReturnsBlurLevelHigh() {
        #expect(VideoEffect.blurHigh.blurLevel == .high)
    }

    @Test("none returns nil blurLevel")
    func noneReturnsNilBlurLevel() {
        #expect(VideoEffect.none.blurLevel == nil)
    }

    @Test("backgroundImage returns nil blurLevel")
    func backgroundImageReturnsNilBlurLevel() {
        let effect = VideoEffect.backgroundImage(id: "beach", imagePath: "/path/beach.jpg")
        #expect(effect.blurLevel == nil)
    }

    // MARK: - Equatable

    @Test("different backgroundImage ids are not equal")
    func differentBackgroundImageIdsAreNotEqual() {
        let a = VideoEffect.backgroundImage(id: "a", imagePath: "/a.jpg")
        let b = VideoEffect.backgroundImage(id: "b", imagePath: "/b.jpg")
        #expect(a != b)
    }

    // MARK: - Codable round-trip

    @Test(arguments: [VideoEffect.none, .blurLow, .blurHigh, .backgroundImage(id: "lib", imagePath: "/lib.jpg")])
    func codableRoundTrip(effect: VideoEffect) throws {
        let data = try JSONEncoder().encode(effect)
        let decoded = try JSONDecoder().decode(VideoEffect.self, from: data)
        #expect(decoded == effect)
    }
}
