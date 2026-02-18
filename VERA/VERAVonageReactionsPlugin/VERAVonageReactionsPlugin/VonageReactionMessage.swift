//
//  Created by Vonage on 11/2/26.
//

import Foundation

/// A reaction payload used for Vonage signal transport.
///
/// Encoded as JSON in the `OutgoingSignal.payload` for sending emoji reactions
/// between call participants.
public struct VonageReactionMessage: Codable, Sendable {
    /// The emoji character.
    public let emoji: String

    /// Timestamp when the reaction was sent.
    public let time: Date

    private enum CodingKeys: String, CodingKey {
        case emoji
        case time
    }

    /// Creates a Vonage reaction payload.
    /// - Parameters:
    ///   - emoji: The emoji character.
    ///   - time: When the reaction was sent. Defaults to now.
    public init(
        emoji: String,
        time: Date = Date()
    ) {
        self.emoji = emoji
        self.time = time
    }

    /// Decodes `time` from a numeric timestamp (milliseconds since epoch).
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        emoji = try container.decode(String.self, forKey: .emoji)
        let timestamp = try container.decode(Double.self, forKey: .time)
        time = Date(timeIntervalSince1970: timestamp / 1000.0)
    }

    /// Encodes `time` as a numeric timestamp (milliseconds since epoch).
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(emoji, forKey: .emoji)
        let timestamp = time.timeIntervalSince1970 * 1000.0
        try container.encode(timestamp, forKey: .time)
    }
}

// MARK: - JSON Encoding

extension VonageReactionMessage {
    /// Encodes the reaction as a JSON string for signal payload transport.
    ///
    /// - Throws: ``ReactionMappingError/invalidJSON`` if encoding fails.
    /// - Returns: A UTF-8 JSON string representing the reaction.
    public func toJSONString() throws -> String {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(self)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ReactionMappingError.invalidJSON
        }

        return jsonString
    }
}
