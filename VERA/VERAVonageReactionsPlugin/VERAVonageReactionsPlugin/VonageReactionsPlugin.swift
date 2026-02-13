//
//  Created by Vonage on 11/2/26.
//

import Foundation
import VERAReactions
import VERAVonage

/// Enables emoji reactions over Vonage signals during video calls.
///
/// `VonageReactionsPlugin` listens for incoming `emoji` signals, maps them into
/// domain `Reaction`s, and publishes them via `ReactionsRepository`.
/// It can also emit reactions through the provided signal channel.
///
/// ## Responsibilities
/// - Handle incoming `emoji` signals and publish to repository
/// - Emit outgoing emoji reactions with username
/// - Maintain per-call state (e.g., current username)
///
/// ## Usage
/// ```swift
/// let plugin = VonageReactionsPlugin(repository: reactionsRepository)
/// pluginRegistry.registerPlugin(plugin: plugin)
/// ```
///
/// - Important: Set `channel` before sending reactions; otherwise throws
///   ``VonageReactionsPlugin/Error/missingChannel``.
/// - SeeAlso: ``VonagePlugin``, ``VonageSignalHandler``, ``VonageSignalEmitter``
public final class VonageReactionsPlugin: VonagePlugin, VonageSignalHandler, VonageSignalEmitter {

    // MARK: - Signal Types

    /// Supported signal types for this plugin.
    public enum SignalType: String {
        /// Emoji reactions routed via Vonage signaling.
        case emoji
    }

    // MARK: - Errors

    /// Errors emitted by the reactions plugin.
    public enum Error: Swift.Error, LocalizedError {
        /// The signal channel is not set when attempting to emit a reaction.
        case missingChannel

        public var errorDescription: String? {
            switch self {
            case .missingChannel:
                return "Signal channel is not available. Ensure you are connected to a call."
            }
        }
    }

    // MARK: - Properties

    /// The channel used to emit signals to peers; injected by the call façade.
    public weak var channel: (any VonageSignalChannel)?

    /// The current username associated with this call.
    private var username: String = ""

    /// Repository used to publish and observe reactions.
    public let repository: ReactionsRepository

    /// Stable identifier for plugin registration and diagnostics.
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    // MARK: - Initialization

    /// Creates a reactions plugin.
    ///
    /// - Parameter repository: A reactions repository. Defaults to `DefaultReactionsRepository()`.
    public init(repository: ReactionsRepository = DefaultReactionsRepository()) {
        self.repository = repository
    }

    // MARK: - VonagePluginCallLifeCycle

    /// Lifecycle callback when the call starts.
    ///
    /// Extracts the username from the provided `userInfo` dictionary to tag outgoing reactions.
    ///
    /// - Parameter userInfo: Metadata including username.
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        username = userInfo[VonageCallParams.username.rawValue] as? String ?? ""
    }

    /// Lifecycle callback when the call ends.
    ///
    /// Clears in-memory state and repository reactions.
    public func callDidEnd() async throws {
        cleanUp()
    }

    // MARK: - VonageSignalHandler

    /// Processes an incoming Vonage signal.
    ///
    /// Accepts only `emoji` signals. Attempts to decode the signal payload
    /// and publishes the reaction to the repository.
    ///
    /// - Parameter signal: The received signal with type and optional data payload.
    public func handleSignal(_ signal: VonageSignal) {
        guard signal.type == SignalType.emoji.rawValue else { return }

        do {
            let reaction = try mapSignalToReaction(signal)
            Task {
                await repository.addReaction(reaction)
            }
        } catch {
            print("[VonageReactionsPlugin] Failed to parse reaction: \(error.localizedDescription)")
        }
    }

    // MARK: - Send Reaction

    /// Sends an emoji reaction over the signal channel.
    ///
    /// Builds a `VonageReactionMessage`, encodes it to JSON, and emits an `OutgoingSignal`
    /// with type `emoji` through the configured channel.
    ///
    /// - Parameter emoji: The emoji item to send.
    /// - Throws: ``VonageReactionsPlugin/Error/missingChannel`` if `channel` is `nil`,
    ///   or mapping errors if encoding fails.
    public func sendReaction(_ emoji: String) throws {
        guard let channel = channel else {
            throw Error.missingChannel
        }

        let message = VonageReactionMessage(
            participantName: username,
            emoji: emoji
        )

        let signal = OutgoingSignal(
            type: SignalType.emoji.rawValue,
            payload: try message.toJSONString()
        )

        try channel.emitSignal(signal)
    }

    // MARK: - Private

    private func cleanUp() {
        Task {
            await repository.clear()
        }
    }

    private func mapSignalToReaction(_ signal: VonageSignal) throws -> EmojiReaction {
        guard let signalData = signal.data, !signalData.isEmpty else {
            throw ReactionMappingError.missingData
        }

        let jsonData = Data(signalData.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let message = try decoder.decode(VonageReactionMessage.self, from: jsonData)

            let participantName = message.participantName
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = message.emoji
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !emoji.isEmpty else {
                throw ReactionMappingError.invalidEmoji
            }

            return EmojiReaction(
                participantName: participantName,
                emoji: emoji,
                timestamp: message.timestamp
            )

        } catch is DecodingError {
            throw ReactionMappingError.invalidJSON
        }
    }
}
