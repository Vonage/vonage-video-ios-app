//
//  Created by Vonage on 25/1/26.
//

import Foundation
import Testing
import VERABackgroundEffects

@Suite("BackgroundBlur Tests")
struct BackgroundBlurTests {

    @Test func keyIsBackgroundBlur() {
        #expect(BackgroundBlur.key == "BackgroundBlur")
    }

    @Test(arguments: [BlurLevel.low, .high, .none])
    func paramsGeneratesValidJSONForBlurLevel(blurLevel: BlurLevel) throws {
        let sut = makeSUT()

        let params = try sut.params(blurLevel: blurLevel)

        #expect(params.contains("radius"))
        #expect(!params.isEmpty)
    }

    @Test func paramsGeneratesCorrectJSONForLowBlurLevel() throws {
        let sut = makeSUT()

        let params = try sut.params(blurLevel: .low)

        #expect(params.contains("\"radius\":\"Low\""))
    }

    @Test func paramsGeneratesCorrectJSONForHighBlurLevel() throws {
        let sut = makeSUT()

        let params = try sut.params(blurLevel: .high)

        #expect(params.contains("\"radius\":\"High\""))
    }

    @Test func paramsGeneratesCorrectJSONForNoneBlurLevel() throws {
        let sut = makeSUT()

        let params = try sut.params(blurLevel: .none)

        #expect(params.contains("\"radius\":\"None\""))
    }

    @Test func paramsReturnsDecodableJSON() throws {
        let sut = makeSUT()

        let params = try sut.params(blurLevel: .low)
        let data = params.data(using: .utf8)

        #expect(data != nil)
        let decoded = try JSONDecoder().decode(Radius.self, from: data!)
        #expect(decoded.radius == .low)
    }

    @Test func radiusInitializesWithBlurLevel() {
        let radius = Radius(radius: .high)

        #expect(radius.radius == .high)
    }

    @Test(arguments: [BlurLevel.low, .high, .none])
    func radiusEncodesCorrectly(blurLevel: BlurLevel) throws {
        let radius = Radius(radius: blurLevel)

        let data = try JSONEncoder().encode(radius)
        let decoded = try JSONDecoder().decode(Radius.self, from: data)

        #expect(decoded.radius == blurLevel)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> BackgroundBlur {
        BackgroundBlur()
    }
}
