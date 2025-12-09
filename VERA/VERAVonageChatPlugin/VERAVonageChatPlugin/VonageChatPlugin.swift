//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERAChat
import VERAVonage

/// Enables chat over Vonage signals and bridges to the chat repository.
///
/// `VonageChatPlugin` listens for incoming chat signals, maps them into
/// domain `ChatMessage`s, and persists them via `ChatMessagesRepository`.
/// It can also emit chat messages through the provided signal channel.
///
/// ## Responsibilities
/// - Handle incoming `chat` signals and persist messages
/// - Emit outgoing chat messages with username and text
/// - Maintain per-call state (e.g., current username)
///
/// - Important: Set `channel` before sending messages; otherwise throws ``VonageChatPlugin/Error/missingChannel``.
/// - SeeAlso: ``VonagePlugin``, ``VonageSignalHandler``, ``VonageSignalEmitter``, ``VonageSignal``, ``OutgoingSignal``
public final class VonageChatPlugin: VonagePlugin, VonageSignalHandler, VonageSignalEmitter {

    /// Supported signal types for this plugin.
    public enum SignalType: String {
        /// Chat messages routed via Vonage signaling.
        case chat
    }

    /// Errors emitted by the chat plugin.
    public enum Error: Swift.Error {
        /// The signal channel is not set when attempting to emit a message.
        case missingChannel
    }

    /// The channel used to emit signals to peers; injected by the call façade.
    public weak var channel: (any VERAVonage.VonageSignalChannel)?
    /// The current username associated with this call.
    private var username: String = ""
    /// Repository used to persist and observe chat messages.
    public let repository: ChatMessagesRepository
    /// Stable identifier for plugin registration and diagnostics.
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a chat plugin.
    ///
    /// - Parameter repository: A messages repository. Defaults to `DefaultChatMessagesRepository()`.
    public init(repository: ChatMessagesRepository = DefaultChatMessagesRepository()) {
        self.repository = repository
    }

    /// Processes an incoming Vonage signal.
    ///
    /// Accepts only `chat` signals. Attempts to map the signal payload to `ChatMessage`
    /// via ``VERAVonage/VonageSignal/toChatMessage(date:)`` and stores it in the repository.
    ///
    /// - Parameter signal: The received signal with type and optional data payload.
    public func handleSignal(_ signal: VERAVonage.VonageSignal) {
        guard signal.type == SignalType.chat.rawValue else { return }

        do {
            let chatMessage = try signal.toChatMessage()
            repository.addMessage(chatMessage)
        } catch {
            print(error.localizedDescription)
        }
    }

    /// Lifecycle callback when the call starts.
    ///
    /// Extracts the username from the provided `userInfo` dictionary to tag outgoing messages.
    ///
    /// - Parameter userInfo: Metadata including ``VonageCallParams/username``.
    public func callDidStart(_ userInfo: [String: Any]) {
        username = userInfo.username
    }

    /// Lifecycle callback when the call ends.
    ///
    /// Clears in-memory state and repository messages.
    public func callDidEnd() {
        cleanUp()
    }

    /// Sends a chat message over the signal channel.
    ///
    /// Builds an `VonageChatMessage`, encodes it to JSON, and emits an ``OutgoingSignal``
    /// with type ``SignalType/chat`` through the configured channel.
    ///
    /// - Parameter message: The text to send.
    /// - Throws: ``VonageChatPlugin/Error/missingChannel`` if `channel` is `nil`,
    ///   or mapping errors if encoding fails.
    public func sendMessage(_ message: String) throws {
        guard let channel = channel else {
            throw Error.missingChannel
        }

        let vonageMessage = VonageChatMessage(
            participantName: username,
            text: message
        )

        let signal = OutgoingSignal(
            type: SignalType.chat.rawValue,
            payload: try vonageMessage.toJSONString()
        )
        try channel.emitSignal(signal)
    }

    /// Clears chat-related state and messages.
    private func cleanUp() {
        repository.clearMessages()
    }
}

extension [String: Any] {
    /// Convenience accessor for username in `userInfo` dictionaries.
    fileprivate var username: String {
        self[VonageCallParams.username.rawValue] as? String ?? ""
    }
}

/// A message payload used for Vonage signal transport.
///
/// Encoded as JSON in the `OutgoingSignal.payload`, then mapped to domain `ChatMessage`.
public struct VonageChatMessage: Codable {
    /// Sender display name.
    public let participantName: String
    /// Message content.
    public let text: String

    /// Creates an Vonage chat payload.
    public init(participantName: String, text: String) {
        self.participantName = participantName
        self.text = text
    }
}

extension VERAVonage.VonageSignal {

    /// Maps an incoming `VonageSignal` to a domain `ChatMessage`.
    ///
    /// - Parameter date: Optional timestamp for the message; defaults to `Date()`.
    /// - Throws: ``ChatMappingError`` if data is missing or invalid JSON, or
    ///   if the username/message content is empty.
    /// - Returns: A validated domain compliant `ChatMessage`.
    public func toChatMessage(date: Date = Date()) throws -> ChatMessage {
        guard let signalData = data, !signalData.isEmpty else {
            throw ChatMappingError.missingData
        }

        let jsonData = Data(signalData.utf8)

        do {
            let vonageMessage = try JSONDecoder().decode(VonageChatMessage.self, from: jsonData)

            let username = vonageMessage.participantName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let message = vonageMessage.text
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !username.isEmpty else {
                throw ChatMappingError.invalidParticipantName
            }

            guard !message.isEmpty else {
                throw ChatMappingError.emptyMessage
            }

            return ChatMessage(
                username: username,
                message: message,
                date: date
            )

        } catch DecodingError.dataCorrupted(_) {
            throw ChatMappingError.invalidJSON
        } catch is DecodingError {
            throw ChatMappingError.invalidJSON
        } catch {
            throw error
        }
    }
}

/// Errors that can occur while mapping signal payloads to chat messages.
public enum ChatMappingError: LocalizedError {
    /// Signal payload is missing or empty.
    case missingData
    /// JSON payload is invalid or cannot be decoded.
    case invalidJSON
    /// Participant name is empty or invalid.
    case invalidParticipantName
    /// Message content is empty.
    case emptyMessage

    public var errorDescription: String? {
        switch self {
        case .missingData:
            return "Signal data is missing or empty"
        case .invalidJSON:
            return "Invalid JSON format in signal data"
        case .invalidParticipantName:
            return "Participant name is empty or invalid"
        case .emptyMessage:
            return "Message content is empty"
        }
    }
}

extension VonageChatMessage {
    /// Encodes the message as a JSON string for signal payload transport.
    ///
    /// - Throws: ``ChatMappingError/invalidJSON`` if encoding fails.
    /// - Returns: A UTF-8 JSON string representing the message.
    public func toJSONString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ChatMappingError.invalidJSON
        }

        return jsonString
    }
}
