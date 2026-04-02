//
//  Created by Vonage on 2/4/26.
//

import Combine
import Foundation
import Testing
import VERAReactions

@Suite("EmojiReaction entity tests")
struct EmojiReactionTests {

    @Test("EmojiReaction stores all properties correctly")
    func emojiReactionProperties() {
        let id = UUID()
        let time = Date()
        let reaction = EmojiReaction(
            id: id,
            participantName: "Alice",
            emoji: "👍",
            time: time,
            isMe: true)

        #expect(reaction.id == id)
        #expect(reaction.participantName == "Alice")
        #expect(reaction.emoji == "👍")
        #expect(reaction.time == time)
        #expect(reaction.isMe == true)
    }

    @Test("EmojiReaction defaults")
    func emojiReactionDefaults() {
        let reaction = EmojiReaction(
            participantName: "Bob",
            emoji: "🎉")

        #expect(reaction.participantName == "Bob")
        #expect(reaction.emoji == "🎉")
        #expect(reaction.isMe == false)
    }

    @Test("EmojiReaction equality with same id")
    func emojiReactionEquality() {
        let id = UUID()
        let time = Date()
        let reaction1 = EmojiReaction(
            id: id, participantName: "Alice", emoji: "👍", time: time, isMe: false)
        let reaction2 = EmojiReaction(
            id: id, participantName: "Alice", emoji: "👍", time: time, isMe: false)

        #expect(reaction1 == reaction2)
    }

    @Test("EmojiReaction inequality with different id")
    func emojiReactionInequalityById() {
        let time = Date()
        let reaction1 = EmojiReaction(
            participantName: "Alice", emoji: "👍", time: time)
        let reaction2 = EmojiReaction(
            participantName: "Alice", emoji: "👍", time: time)

        #expect(reaction1 != reaction2)
    }

    @Test("EmojiReaction inequality with different emoji")
    func emojiReactionInequalityByEmoji() {
        let id = UUID()
        let time = Date()
        let reaction1 = EmojiReaction(
            id: id, participantName: "Alice", emoji: "👍", time: time)
        let reaction2 = EmojiReaction(
            id: id, participantName: "Alice", emoji: "❤️", time: time)

        #expect(reaction1 != reaction2)
    }

    @Test("EmojiReaction generates unique id by default")
    func emojiReactionGeneratesUniqueId() {
        let reaction1 = EmojiReaction(participantName: "A", emoji: "👍")
        let reaction2 = EmojiReaction(participantName: "A", emoji: "👍")

        #expect(reaction1.id != reaction2.id)
    }
}
