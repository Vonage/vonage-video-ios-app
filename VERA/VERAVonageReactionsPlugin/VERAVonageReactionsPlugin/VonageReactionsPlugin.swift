//
//  Created by Vonage on 11/2/26.
//

import Combine
import Foundation
import VERADomain
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
/// - Emit outgoing emoji reactions
/// - Resolve participant names from connection IDs via ``CallFacade``
///
/// ## Usage
/// ```swift
/// let plugin = VonageReactionsPlugin(repository: reactionsRepository)
/// pluginRegistry.registerPlugin(plugin: plugin)
/// ```
///
/// - Important: Set `channel` before sending reactions; otherwise throws
///   ``VonageReactionsPlugin/Error/missingChannel``.
/// - SeeAlso: ``VonagePlugin``, ``VonageSignalHandler``, ``VonageSignalEmitter``, ``VonagePluginCallHolder``
public final class VonageReactionsPlugin: VonagePlugin, VonageSignalHandler, VonageSignalEmitter, VonagePluginCallHolder
{

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

    /// The active call façade, used to resolve participant names from connection IDs.
    public weak var call: CallFacade? {
        didSet {
            observeParticipants()
        }
    }

    /// Connection ID of the local participant, used to determine isMe.
    private var localConnectionId: String?

    /// Current participants snapshot for resolving connectionId → name.
    private var participants: [Participant] = []

    /// Subscription for participants publisher.
    private var participantsCancellable: AnyCancellable?

    /// Incoming signal pipeline serialized onto the main queue.
    private let signalSubject = PassthroughSubject<VonageSignal, Never>()

    /// Subscription for the signal processing pipeline.
    private var signalCancellable: AnyCancellable?

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
    /// - Parameter userInfo: Metadata including call context.
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        // No per-call state needed; participant names resolved via CallFacade.
        observeSignals()
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
    /// Accepts only `emoji` signals. The signal is forwarded to a Combine pipeline
    /// that serializes processing onto the main queue, ensuring thread-safe access
    /// to `participants` and `localConnectionId`.
    ///
    /// - Parameter signal: The received signal with type and optional data payload.
    public func handleSignal(_ signal: VonageSignal) {
        guard signal.type == SignalType.emoji.rawValue else { return }
        signalSubject.send(signal)
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

        let message = VonageReactionMessage(emoji: emoji)

        let signal = OutgoingSignal(
            type: SignalType.emoji.rawValue,
            payload: try message.toJSONString()
        )

        try channel.emitSignal(signal)
    }

    // MARK: - Private

    private func cleanUp() {
        participantsCancellable?.cancel()
        participantsCancellable = nil
        signalCancellable?.cancel()
        signalCancellable = nil
        participants = []
        localConnectionId = nil
    }

    private func observeSignals() {
        signalCancellable?.cancel()
        signalCancellable =
            signalSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                guard let self else { return }
                do {
                    let reaction = try self.mapSignalToReaction(signal)
                    Task {
                        await self.repository.addReaction(reaction)
                    }
                } catch {
                    print("[VonageReactionsPlugin] Failed to parse reaction: \(error.localizedDescription)")
                }
            }
    }

    private func observeParticipants() {
        participantsCancellable?.cancel()
        participantsCancellable = call?.participantsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                var allParticipants = state.participants
                if let local = state.localParticipant {
                    allParticipants.append(local)
                    self?.localConnectionId = local.connectionId
                }
                self?.participants = allParticipants
            }
    }

    private func resolveParticipantName(for connectionId: String?) -> String {
        guard let connectionId else { return "" }
        return participants.first { $0.connectionId == connectionId }?.name ?? ""
    }

    private func isLocalUser(connectionId: String?) -> Bool {
        guard let connectionId, let localConnectionId else { return false }
        return connectionId == localConnectionId
    }

    private func mapSignalToReaction(_ signal: VonageSignal) throws -> EmojiReaction {
        guard let signalData = signal.data, !signalData.isEmpty else {
            throw ReactionMappingError.missingData
        }

        let jsonData = Data(signalData.utf8)
        let decoder = JSONDecoder()

        do {
            let message = try decoder.decode(VonageReactionMessage.self, from: jsonData)

            let emoji = message.emoji
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !emoji.isEmpty else {
                throw ReactionMappingError.invalidEmoji
            }

            return EmojiReaction(
                participantName: resolveParticipantName(for: signal.connectionId),
                emoji: emoji,
                time: message.time,
                isMe: isLocalUser(connectionId: signal.connectionId)
            )

        } catch is DecodingError {
            throw ReactionMappingError.invalidJSON
        }
    }
}
