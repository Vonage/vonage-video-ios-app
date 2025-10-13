//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERAChat

extension ChatMessage {
    private static let mockDate: Date = Date(timeIntervalSince1970: 1_760_352_680)

    private static func formattedDateByAdding(_ interval: TimeInterval = 0) -> Date {
        mockDate.addingTimeInterval(interval)
    }

    /**
     * Sorted from oldest to newest
     */
    public static let sampleMessages: [ChatMessage] = [
        ChatMessage(
            username: "Arthur Dent",
            message: "Don't panic! I've got my towel.",
            date: formattedDateByAdding()
        ),
        ChatMessage(
            username: "Ford Prefect",
            message: "Time is an illusion. Lunchtime doubly so.",
            date: formattedDateByAdding(5)
        ),
        ChatMessage(
            username: "Zaphod Beeblebrox IV",
            message: "Hey guys! Just stole a ship. The Infinite Improbability Drive is absolutely froody!",
            date: formattedDateByAdding(10)
        ),
        ChatMessage(
            username: "Deep Thought",
            message: "The Answer to the Great Question of Life, the Universe and Everything is Forty-two.",
            date: formattedDateByAdding(300)
        ),
        ChatMessage(
            username: "Marvin",
            message: "Life? Don't talk to me about life.",
            date: formattedDateByAdding(500)
        ),
        ChatMessage(
            username: "Trillian",
            message: "So long and thanks for all the fish!",
            date: formattedDateByAdding(600)
        ),
        ChatMessage(
            username: "The Whale",
            message: "Oh no, not again. I wonder if it will be friends with me?",
            date: formattedDateByAdding(9900)
        ),
    ]
}
