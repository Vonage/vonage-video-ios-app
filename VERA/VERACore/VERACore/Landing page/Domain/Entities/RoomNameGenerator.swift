//
//  Created by Vonage on 10/7/25.
//

import Foundation

public struct RoomNameGenerator {

    public struct Category {
        public let words: [String]

        public init(words: [String]) {
            self.words = words
        }
    }

    private let categories: [Category]

    public init(categories: [Category]) {
        self.categories = categories
    }

    public func generate() -> String {
        if categories.isEmpty {
            return ""
        }
        return categories.reduce("") { partialResult, category in
            if partialResult.isEmpty {
                return category.words.randomElement() ?? ""
            } else {
                return partialResult + "-" + (category.words.randomElement() ?? "")
            }
        }
    }
}
