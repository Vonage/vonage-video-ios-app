//
//  Created by Vonage on 18/05/2026.
//

import Foundation
import Testing
import VERABackgroundEffects
import VERADomain

@Suite("BackgroundReplacement Tests")
struct BackgroundReplacementTests {

    @Test("key is BackgroundReplacement")
    func keyIsBackgroundReplacement() {
        #expect(BackgroundReplacement.key == "BackgroundReplacement")
    }

    @Test("params contains image_file_path key")
    func paramsContainsImageFilePathKey() throws {
        let sut = makeSUT()

        let params = try sut.params(imagePath: "/path/to/image.jpg")

        #expect(params.contains("image_file_path"))
    }

    @Test("params contains the provided image path")
    func paramsContainsProvidedImagePath() throws {
        let sut = makeSUT()
        let path = "/absolute/path/to/bg.jpg"

        let params = try sut.params(imagePath: path)

        #expect(params.contains(path))
    }

    @Test("params produces valid JSON")
    func paramsProducesValidJSON() throws {
        let sut = makeSUT()

        let params = try sut.params(imagePath: "/path/image.jpg")
        let data = params.data(using: .utf8)

        #expect(data != nil)
        let decoded = try JSONDecoder().decode(ImageParams.self, from: data!)
        #expect(decoded.imageFilePath == "/path/image.jpg")
    }

    @Test("ImageParams encodes to image_file_path JSON key")
    func imageParamsEncodesToImageFilePathKey() throws {
        let imageParams = ImageParams(imageFilePath: "/test.jpg")

        let data = try JSONEncoder().encode(imageParams)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        #expect(json?["image_file_path"] == "/test.jpg")
        #expect(json?["imageFilePath"] == nil)
    }

    @Test("ImageParams round-trips through Codable")
    func imageParamsRoundTrips() throws {
        let original = ImageParams(imageFilePath: "/backgrounds/beach.jpg")

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ImageParams.self, from: data)

        #expect(decoded.imageFilePath == original.imageFilePath)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> BackgroundReplacement {
        BackgroundReplacement()
    }
}
