//
//  Created by Vonage on 11/2/26.
//

import Combine
import SwiftUI
import Testing
import VERADomain
import VERAReactions
import VERAVonage

@testable import VERAVonageReactionsPlugin

@Suite("VonageReactionsPlugin Tests")
struct VonageReactionsPluginTests {

    // MARK: - Send Reaction Tests

    @Test("sendReaction throws when channel is nil")
    func sendReactionThrowsWhenChannelMissing() async throws {
        let sut = VonageReactionsPlugin()
        let emoji = UIEmojiReaction(emoji: "👍", name: "thumbs up")

        #expect(throws: VonageReactionsPlugin.Error.missingChannel) {
            try sut.sendReaction(emoji.emoji)
        }
    }

    @Test("sendReaction emits signal with correct type and payload")
    func sendReactionEmitsCorrectSignal() async throws {
        let mockChannel = MockSignalChannel()
        let sut = VonageReactionsPlugin()
        sut.channel = mockChannel

        let emoji = UIEmojiReaction(emoji: "🎉", name: "party")
        try sut.sendReaction(emoji.emoji)

        #expect(mockChannel.emittedSignals.count == 1)
        #expect(mockChannel.emittedSignals.first?.type == "emoji")

        let payload = mockChannel.emittedSignals.first?.payload ?? ""
        #expect(payload.contains("🎉"))
        #expect(!payload.contains("participantName"))
    }

    // MARK: - Handle Signal Tests

    @Test("handleSignal ignores non-reaction signals")
    func handleSignalIgnoresOtherTypes() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let signal = VonageSignal(type: "chat", data: "{}")
        sut.handleSignal(signal)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        _ = cancellable
    }

    @Test("handleSignal adds reaction to repository with correct fields")
    func handleSignalAddsReaction() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let timestampMs: Double = 1_739_188_800_000
        let payload = "{\"emoji\":\"👋\",\"time\":\(timestampMs)}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-123")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        let reaction = try #require(received.first)
        #expect(reaction.emoji == "👋")
        #expect(reaction.participantName == "")
        #expect(reaction.isMe == false)
        #expect(reaction.time == Date(timeIntervalSince1970: timestampMs / 1000.0))
        _ = cancellable
    }

    @Test("handleSignal ignores signals with missing data")
    func handleSignalIgnoresMissingData() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let signal = VonageSignal(type: "emoji", data: nil)
        sut.handleSignal(signal)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        _ = cancellable
    }

    @Test("handleSignal ignores signals with invalid JSON")
    func handleSignalIgnoresInvalidJSON() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let signal = VonageSignal(type: "emoji", data: "not valid json")
        sut.handleSignal(signal)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        _ = cancellable
    }

    // MARK: - Lifecycle Tests

    @Test("sendReaction works without calling callDidStart")
    func sendReactionWorksWithoutCallDidStart() async throws {
        let mockChannel = MockSignalChannel()
        let sut = VonageReactionsPlugin()
        sut.channel = mockChannel

        let emoji = UIEmojiReaction(emoji: "👍", name: "thumbs up")
        try sut.sendReaction(emoji.emoji)

        let payload = mockChannel.emittedSignals.first?.payload ?? ""
        #expect(payload.contains("👍"))
    }

    // MARK: - Participant Name Resolution Tests

    @Test("handleSignal resolves participantName from connectionId via call participants")
    func handleSignalResolvesParticipantName() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let remoteParticipant = makeParticipant(id: "p1", connectionId: "conn-alice", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: [remoteParticipant], activeParticipantId: nil)
        )
        sut.call = mockCall
        try await sut.callDidStart([:])

        // Allow the Combine subscription to propagate
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\"🎉\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-alice")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.participantName == "Alice")
        _ = cancellable
    }

    @Test("handleSignal returns empty name for unknown connectionId")
    func handleSignalReturnsEmptyNameForUnknownConnectionId() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let remoteParticipant = makeParticipant(id: "p1", connectionId: "conn-alice", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: nil, participants: [remoteParticipant], activeParticipantId: nil)
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\"👋\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-unknown")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.participantName == "")
        _ = cancellable
    }

    // MARK: - isMe Detection Tests

    @Test("handleSignal sets isMe true when connectionId matches local participant")
    func handleSignalSetsIsMeTrueForLocalUser() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let localParticipant = makeParticipant(id: "local", connectionId: "conn-local", name: "Me")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: localParticipant, participants: [], activeParticipantId: nil)
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\"👍\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-local")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.isMe == true)
        _ = cancellable
    }

    @Test("handleSignal sets isMe false for remote connectionId")
    func handleSignalSetsIsMeFalseForRemoteUser() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let localParticipant = makeParticipant(id: "local", connectionId: "conn-local", name: "Me")
        let remoteParticipant = makeParticipant(id: "remote", connectionId: "conn-remote", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(
                localParticipant: localParticipant,
                participants: [remoteParticipant],
                activeParticipantId: nil
            )
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\"👍\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-remote")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.isMe == false)
        _ = cancellable
    }

    @Test("handleSignal sets isMe false when signal connectionId is nil")
    func handleSignalSetsIsMeFalseForNilConnectionId() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let localParticipant = makeParticipant(id: "local", connectionId: "conn-local", name: "Me")
        mockCall._participantsPublisher.send(
            ParticipantsState(localParticipant: localParticipant, participants: [], activeParticipantId: nil)
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\"👍\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: nil)
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.isMe == false)
        _ = cancellable
    }

    // MARK: - Edge Case Tests

    @Test("handleSignal ignores whitespace-only emoji")
    func handleSignalIgnoresWhitespaceOnlyEmoji() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let payload = "{\"emoji\":\" \",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload)
        sut.handleSignal(signal)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        _ = cancellable
    }

    @Test("handleSignal ignores empty string data")
    func handleSignalIgnoresEmptyStringData() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let signal = VonageSignal(type: "emoji", data: "")
        sut.handleSignal(signal)

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        _ = cancellable
    }

    @Test("sendReaction does not add reaction to local repository")
    func sendReactionDoesNotAddToRepository() async throws {
        let repository = MockReactionsRepository()
        let mockChannel = MockSignalChannel()
        let sut = VonageReactionsPlugin(repository: repository)
        sut.channel = mockChannel
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        try sut.sendReaction("🔥")

        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(received.isEmpty)
        #expect(mockChannel.emittedSignals.count == 1)
        _ = cancellable
    }

    // MARK: - Cleanup Tests

    @Test("callDidEnd cancels participant observation and clears state")
    func callDidEndCancelsObservationAndClearsState() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let localParticipant = makeParticipant(id: "local", connectionId: "conn-local", name: "Me")
        let remoteParticipant = makeParticipant(id: "remote", connectionId: "conn-remote", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(
                localParticipant: localParticipant,
                participants: [remoteParticipant],
                activeParticipantId: nil
            )
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        try await sut.callDidEnd()

        // Restart signal pipeline so handleSignal works again
        try await sut.callDidStart([:])

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        // After cleanup, name resolution should return empty string
        let payload = "{\"emoji\":\"👋\",\"time\":1739188800000}"
        let signal = VonageSignal(type: "emoji", data: payload, connectionId: "conn-remote")
        sut.handleSignal(signal)

        try await waitUntil { received.count == 1 }

        #expect(received.first?.participantName == "")
        #expect(received.first?.isMe == false)
        _ = cancellable
    }

    // MARK: - Plugin Identifier

    @Test("pluginIdentifier returns correct value")
    func pluginIdentifierReturnsCorrectValue() {
        let sut = VonageReactionsPlugin()
        #expect(sut.pluginIdentifier == "VonageReactionsPlugin")
    }

    // MARK: - Burst Traffic Tests

    @Test("handleSignal processes rapid burst of signals without losing any")
    func handleSignalProcessesBurstTraffic() async throws {
        let repository = MockReactionsRepository()
        let sut = VonageReactionsPlugin(repository: repository)
        let mockCall = MockCallFacade()

        let localParticipant = makeParticipant(id: "local", connectionId: "conn-local", name: "Me")
        let remoteParticipant = makeParticipant(id: "remote", connectionId: "conn-alice", name: "Alice")
        mockCall._participantsPublisher.send(
            ParticipantsState(
                localParticipant: localParticipant,
                participants: [remoteParticipant],
                activeParticipantId: nil
            )
        )
        sut.call = mockCall
        try await sut.callDidStart([:])
        try await Task.sleep(nanoseconds: 50_000_000)

        let received = Accumulator<EmojiReaction>()
        let cancellable = repository.reactionReceived.sink { received.append($0) }

        let emojis = ["👍", "🎉", "❤️", "😂", "🔥", "👋", "🚀", "👏", "💪", "🙏"]
        let burstCount = emojis.count

        // Fire all signals in a tight loop — no awaiting between sends
        for (index, emoji) in emojis.enumerated() {
            let connectionId = index == 0 ? "conn-local" : "conn-alice"
            let payload = "{\"emoji\":\"\(emoji)\",\"time\":1739188800000}"
            let signal = VonageSignal(type: "emoji", data: payload, connectionId: connectionId)
            sut.handleSignal(signal)
        }

        try await waitUntil(timeout: 2.0) { received.count == burstCount }

        // All signals were processed — none dropped
        #expect(received.count == burstCount)

        // Every emoji arrived (order may vary due to unstructured Task per reaction)
        let receivedEmojis = Set(received.values.map(\.emoji))
        for emoji in emojis {
            #expect(receivedEmojis.contains(emoji))
        }

        // Participant resolution worked under burst: at least one local, at least one remote
        let hasLocal = received.values.contains { $0.isMe == true }
        let hasRemote = received.values.contains { $0.isMe == false && $0.participantName == "Alice" }
        #expect(hasLocal)
        #expect(hasRemote)
        _ = cancellable
    }

    // MARK: - Test Helpers

    /// Polls `condition` every 10 ms, throwing if it hasn't become `true`
    /// within `timeout` seconds.
    private func waitUntil(
        timeout: TimeInterval = 0.5,
        _ condition: @escaping @Sendable () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                throw WaitTimeoutError()
            }
            try await Task.sleep(nanoseconds: 10_000_000)  // 10 ms
        }
    }

    private struct WaitTimeoutError: Error, CustomStringConvertible {
        var description: String { "waitUntil timed out" }
    }

    private func makeParticipant(
        id: String,
        connectionId: String? = nil,
        name: String = "aName"
    ) -> Participant {
        Participant(
            id: id,
            connectionId: connectionId,
            name: name,
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: .zero,
            creationTime: Date(),
            isScreenshare: false,
            isPinned: false,
            view: AnyView(EmptyView())
        )
    }
}

// MARK: - Mocks

/// Accumulator for collecting values emitted by a publisher.
/// Used as a `let` binding so it can be safely captured in `@Sendable` closures.
/// Thread-safe via `NSLock`: the upstream Combine pipeline dispatches reactions
/// through unstructured `Task` blocks that may run concurrently on the
/// cooperative thread pool.
final class Accumulator<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _values: [T] = []

    var values: [T] { lock.withLock { _values } }
    var isEmpty: Bool { lock.withLock { _values.isEmpty } }
    var count: Int { lock.withLock { _values.count } }
    var first: T? { lock.withLock { _values.first } }

    func append(_ value: T) {
        lock.withLock { _values.append(value) }
    }
}

final class MockSignalChannel: VonageSignalChannel, @unchecked Sendable {
    var emittedSignals: [OutgoingSignal] = []

    func emitSignal(_ signal: OutgoingSignal) throws {
        emittedSignals.append(signal)
    }
}

final class MockReactionsRepository: ReactionsRepository, @unchecked Sendable {
    private let subject = PassthroughSubject<EmojiReaction, Never>()

    var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        subject.eraseToAnyPublisher()
    }

    func addReaction(_ reaction: EmojiReaction) async {
        subject.send(reaction)
    }
}

final class MockCallFacade: CallFacade, @unchecked Sendable {

    let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    let _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    lazy var statePublisher: AnyPublisher<SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    var _archivingState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    var isMuted: Bool = false
    var isOnHold: Bool = false
    var areCaptionsEnabled: Bool = false

    let _captionsPublisher = CurrentValueSubject<[CaptionItem], Never>([])
    lazy var captionsPublisher: AnyPublisher<[CaptionItem], Never> = _captionsPublisher.eraseToAnyPublisher()

    func connect() {}
    func disconnect() async throws {}
    func toggleLocalVideo() {}
    func toggleLocalCamera() {}
    func toggleLocalAudio() {}
    func muteLocalMedia(_ isMuted: Bool) { self.isMuted = isMuted }
    func setOnHold(_ isOnHold: Bool) { self.isOnHold = isOnHold }
    func enableCaptions() async {}
    func disableCaptions() async {}
}
