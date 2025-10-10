//
//  Created by Vonage on 10/10/25.
//

import Foundation

// MARK: - UI Chat Message Model
struct UIChatMessage: Identifiable, Equatable {
    let id = UUID()
    let username: String
    let message: String
    let date: String

    static func == (lhs: UIChatMessage, rhs: UIChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sample Data
extension UIChatMessage {
    static let sampleMessages: [UIChatMessage] = [
        UIChatMessage(
            username: "Arthur Dent",
            message: "Don't panic! I've got my towel.",
            date: "02:45 PM"
        ),
        UIChatMessage(
            username: "Ford Prefect",
            message: "Time is an illusion. Lunchtime doubly so.",
            date: "02:46 PM"
        ),
        UIChatMessage(
            username: "Zaphod Beeblebrox IV",
            message: "Hey guys! Just stole a ship. The Infinite Improbability Drive is absolutely froody!",
            date: "02:47 PM"
        ),
        UIChatMessage(
            username: "Deep Thought",
            message: "The Answer to the Great Question of Life, the Universe and Everything is Forty-two.",
            date: "02:48 PM"
        ),
        UIChatMessage(
            username: "Marvin",
            message: "Life? Don't talk to me about life.",
            date: "02:49 PM"
        ),
        UIChatMessage(
            username: "Trillian",
            message: "So long and thanks for all the fish!",
            date: "02:50 PM"
        ),
        UIChatMessage(
            username: "The Whale",
            message: "Oh no, not again. I wonder if it will be friends with me?",
            date: "02:51 PM"
        ),
    ]
}
