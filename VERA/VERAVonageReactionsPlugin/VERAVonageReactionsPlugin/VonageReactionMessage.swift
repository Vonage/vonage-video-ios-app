//
//  VonageReactionMessage.swift
//  VERAVonageReactionsPlugin
//

import Foundation

/// A reaction payload used for Vonage signal transport.
///
/// Encoded as JSON in the `OutgoingSignal.payload` for sending emoji reactions
/// between call participants.
public struct VonageReactionMessage: Codable, Sendable {
    /// Sender display name.
    public let participantName: String

    /// The emoji character.
    public let emoji: String

    /// Timestamp when the reaction was sent.
    public let timestamp: Date

    /// Creates a Vonage reaction payload.
    /// - Parameters:
    ///   - participantName: Name of the sender.
    ///   - emoji: The emoji character.
    ///   - timestamp: When the reaction was sent. Defaults to now.
    public init(
        participantName: String,
        emoji: String,
        timestamp: Date = Date()
    ) {
        self.participantName = participantName
        self.emoji = emoji
        self.timestamp = timestamp
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
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(self)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ReactionMappingError.invalidJSON
        }

        return jsonString
    }
}
