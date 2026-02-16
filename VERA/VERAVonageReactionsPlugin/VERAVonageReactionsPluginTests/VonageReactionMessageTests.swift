//
//  Created by Vonage on 16/2/26.
//

import Foundation
import Testing

@testable import VERAVonageReactionsPlugin

@Suite("VonageReactionMessage Tests")
struct VonageReactionMessageTests {

    // MARK: - Encoding Tests

    @Test("encode produces numeric millisecond timestamp")
    func encodeProducesNumericTimestamp() throws {
        let date = Date(timeIntervalSince1970: 1_739_188_800)  // 2026-02-10T12:00:00Z
        let message = VonageReactionMessage(emoji: "👋", time: date)

        let jsonString = try message.toJSONString()

        #expect(jsonString.contains("1739188800000"))
        #expect(!jsonString.contains("2026"))
    }

    @Test("encode includes emoji in payload")
    func encodeIncludesEmoji() throws {
        let message = VonageReactionMessage(emoji: "🎉")

        let jsonString = try message.toJSONString()

        #expect(jsonString.contains("🎉"))
    }

    @Test("encode does not include participantName")
    func encodeDoesNotIncludeParticipantName() throws {
        let message = VonageReactionMessage(emoji: "👍")

        let jsonString = try message.toJSONString()

        #expect(!jsonString.contains("participantName"))
    }

    // MARK: - Decoding Tests

    @Test("decode parses numeric millisecond timestamp correctly")
    func decodesParsesNumericTimestamp() throws {
        let json = "{\"emoji\":\"👋\",\"time\":1739188800000}"
        let data = Data(json.utf8)

        let message = try JSONDecoder().decode(VonageReactionMessage.self, from: data)

        #expect(message.emoji == "👋")
        #expect(message.time == Date(timeIntervalSince1970: 1_739_188_800))
    }

    @Test("decode fails for ISO 8601 string timestamp")
    func decodeFailsForISO8601String() {
        let json = "{\"emoji\":\"👋\",\"time\":\"2026-02-10T12:00:00Z\"}"
        let data = Data(json.utf8)

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(VonageReactionMessage.self, from: data)
        }
    }

    // MARK: - Round-trip Tests

    @Test("encode then decode preserves emoji and time")
    func roundTripPreservesEmojiAndTime() throws {
        let originalDate = Date(timeIntervalSince1970: 1_739_188_800)
        let original = VonageReactionMessage(emoji: "🔥", time: originalDate)

        let jsonString = try original.toJSONString()
        let jsonData = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(VonageReactionMessage.self, from: jsonData)

        #expect(decoded.emoji == original.emoji)
        #expect(decoded.time == original.time)
    }

    @Test("round-trip preserves sub-second precision")
    func roundTripPreservesSubSecondPrecision() throws {
        let originalDate = Date(timeIntervalSince1970: 1_739_188_800.123)
        let original = VonageReactionMessage(emoji: "✨", time: originalDate)

        let jsonString = try original.toJSONString()
        let jsonData = Data(jsonString.utf8)
        let decoded = try JSONDecoder().decode(VonageReactionMessage.self, from: jsonData)

        #expect(abs(decoded.time.timeIntervalSince1970 - original.time.timeIntervalSince1970) < 0.001)
    }
}
