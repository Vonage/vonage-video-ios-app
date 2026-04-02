//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERAVonageReactionsPlugin

@Suite("ReactionMappingError tests")
struct ReactionMappingErrorTests {

    @Test("ReactionMappingError missingData has correct description")
    func missingDataDescription() {
        let error = ReactionMappingError.missingData

        #expect(error.errorDescription == "Signal data is missing or empty")
    }

    @Test("ReactionMappingError invalidJSON has correct description")
    func invalidJSONDescription() {
        let error = ReactionMappingError.invalidJSON

        #expect(error.errorDescription == "Invalid JSON format in signal data")
    }

    @Test("ReactionMappingError invalidEmoji has correct description")
    func invalidEmojiDescription() {
        let error = ReactionMappingError.invalidEmoji

        #expect(error.errorDescription == "Emoji is empty or invalid")
    }

    @Test("ReactionMappingError conforms to LocalizedError")
    func conformsToLocalizedError() {
        let error: LocalizedError = ReactionMappingError.missingData

        #expect(error.errorDescription != nil)
    }

    @Test(
        "All ReactionMappingError cases have non-empty descriptions",
        arguments: [
            ReactionMappingError.missingData,
            ReactionMappingError.invalidJSON,
            ReactionMappingError.invalidEmoji,
        ])
    func allCasesHaveDescriptions(error: ReactionMappingError) {
        #expect(error.errorDescription != nil)
        #expect(error.errorDescription?.isEmpty == false)
    }
}
