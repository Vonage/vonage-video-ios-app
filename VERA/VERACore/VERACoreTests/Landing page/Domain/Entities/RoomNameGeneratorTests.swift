//
//  Created by Vonage on 10/7/25.
//

import Foundation
import Testing
import VERACore

@Suite("Room name generator tests")
struct RoomNameGeneratorTests {

    @Test
    func givenNoCategoriesThenProduceEmptyString() {
        let sut = makeSUT()

        let result = sut.generate()

        #expect(result.isEmpty)
    }

    @Test
    func givenACategoryThenChooseAWord() {
        let categories: [RoomNameGenerator.Category] = [.init(words: ["aardvark"])]
        let sut = makeSUT(categories: categories)

        let result = sut.generate()

        #expect(result == "aardvark")
    }

    @Test
    func givenTwoCategoriesThenChooseTwoWords() {
        let categories: [RoomNameGenerator.Category] = [
            .init(words: ["aardvark"]),
            .init(words: ["aardvark"]),
        ]
        let sut = makeSUT(categories: categories)

        let result = sut.generate()

        #expect(result == "aardvark-aardvark")
    }

    @Test
    func givenTwoCategoriesWithMultipleWordsThenChooseTwoRandomWords() {
        let categories: [RoomNameGenerator.Category] = [
            .init(words: ["aardvark", "albatross"]),
            .init(words: ["aardvark", "alpaca"]),
        ]
        let sut = makeSUT(categories: categories)

        let result = sut.generate()

        #expect(result.split(separator: "-").count == 2)
    }

    // MARK: SUT

    func makeSUT(
        categories: [RoomNameGenerator.Category] = []
    ) -> RoomNameGenerator {
        return RoomNameGenerator(categories: categories)
    }
}
