//
//  Created by Vonage on 10/10/25.
//

import Foundation

// MARK: - UI Chat Message Model
public struct UIChatMessage: Identifiable, Equatable, Hashable {
    public let id = UUID()
    public let username: String
    public let message: String
    public let date: String

    public init(username: String, message: String, date: String) {
        self.username = username
        self.message = message
        self.date = date
    }

    public static func == (lhs: UIChatMessage, rhs: UIChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

extension UIChatMessage {
    public static func formattedDate(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }
}

// MARK: - Sample Data
extension UIChatMessage {
    private static let mockDate: Date = Date(timeIntervalSince1970: 1_760_352_680)

    private static func formattedDateByAdding(_ interval: TimeInterval = 0) -> String {
        UIChatMessage.formattedDate(mockDate.addingTimeInterval(interval))
    }

    /**
     * Sorted from oldest to newest
     */
    public static let sampleMessages: [UIChatMessage] = [
        UIChatMessage(
            username: "Arthur Dent",
            message: "Don't panic! I've got my towel.",
            date: formattedDateByAdding()
        ),
        UIChatMessage(
            username: "Ford Prefect",
            message: "Time is an illusion. Lunchtime doubly so.",
            date: formattedDateByAdding(5)
        ),
        UIChatMessage(
            username: "Zaphod Beeblebrox IV",
            message: "Hey guys! Just stole a ship. The Infinite Improbability Drive is absolutely froody!",
            date: formattedDateByAdding(10)
        ),
        UIChatMessage(
            username: "Deep Thought",
            message: "The Answer to the Great Question of Life, the Universe and Everything is Forty-two.",
            date: formattedDateByAdding(300)
        ),
        UIChatMessage(
            username: "Marvin",
            message: "Life? Don't talk to me about life.",
            date: formattedDateByAdding(500)
        ),
        UIChatMessage(
            username: "Trillian",
            message: "So long and thanks for all the fish!",
            date: formattedDateByAdding(600)
        ),
        UIChatMessage(
            username: "The Whale",
            message: "Oh no, not again. I wonder if it will be friends with me?",
            date: formattedDateByAdding(9900)
        ),
    ]
}
