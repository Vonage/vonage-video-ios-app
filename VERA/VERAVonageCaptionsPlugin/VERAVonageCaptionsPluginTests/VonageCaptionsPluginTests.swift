//
//  Created by Vonage on 20/02/2026.
//

import Combine
import Foundation
import Testing
import VERACaptions
import VERADomain
import VERAVonage

@testable import VERAVonageCaptionsPlugin

@Suite("VonageCaptionsPlugin Tests")
@MainActor
struct VonageCaptionsPluginTests {

    // MARK: - Plugin Identifier

    @Test("Plugin identifier returns correct value")
    func pluginIdentifierReturnsCorrectValue() {
        let (sut, _) = makeSUT()

        #expect(sut.pluginIdentifier == "VonageCaptionsPlugin")
    }

    // MARK: - Call Did Start

    @Test("callDidStart does not throw")
    func callDidStartDoesNotThrow() async throws {
        let (sut, _) = makeSUT()

        try await sut.callDidStart([:])
    }

    @Test("callDidStart subscribes to captions state and enables captions on call")
    func callDidStartEnablesCaptionsOnStateChange() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        mocks.statusDataSource.set(captionsState: .enabled("captions-123"))

        try await waitUntil { mocks.call.recordedActions.contains(.enableCaptions) }

        #expect(mocks.call.areCaptionsEnabled)
    }

    @Test("callDidStart subscribes to captions state and disables captions on call")
    func callDidStartDisablesCaptionsOnStateChange() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        mocks.statusDataSource.set(captionsState: .enabled("captions-123"))
        try await sut.callDidStart([:])

        try await waitUntil { mocks.call.recordedActions.contains(.enableCaptions) }

        mocks.statusDataSource.set(captionsState: .disabled)

        try await waitUntil { mocks.call.recordedActions.contains(.disableCaptions) }

        #expect(!mocks.call.areCaptionsEnabled)
    }

    @Test("callDidStart forwards captions from call to repository")
    func callDidStartForwardsCaptionsToRepository() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        let captions = [
            CaptionItem(speakerName: "Alice", text: "Hello!"),
            CaptionItem(speakerName: "Bob", text: "Hi there"),
        ]
        mocks.call._captionsPublisher.send(captions)

        try await waitUntil { mocks.repository.lastCaptions?.count == 2 }

        #expect(mocks.repository.lastCaptions == captions)
    }

    @Test("callDidStart forwards multiple caption updates to repository")
    func callDidStartForwardsMultipleUpdates() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        mocks.call._captionsPublisher.send(first)
        try await waitUntil { mocks.repository.lastCaptions == first }

        let countAfterFirst = mocks.repository.updateCallCount

        let second = [
            CaptionItem(speakerName: "Alice", text: "First"),
            CaptionItem(speakerName: "Bob", text: "Second"),
        ]
        mocks.call._captionsPublisher.send(second)
        try await waitUntil { mocks.repository.lastCaptions == second }

        #expect(mocks.repository.updateCallCount > countAfterFirst)
    }

    @Test("Repeated starts retain exactly one captions and status subscription")
    func repeatedStartsKeepOneSubscriptionPair() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        for _ in 0..<3 { try await sut.callDidStart([:]) }

        #expect(mocks.call.captionSubscriptions.activeCount == 1)
        #expect(mocks.statusDataSource.subscriptions.activeCount == 1)
        let captions = [CaptionItem(speakerName: "Alice", text: "Still listening")]
        mocks.call._captionsPublisher.send(captions)
        try await waitUntil { mocks.repository.lastCaptions == captions }

        try await sut.callDidEnd()
        #expect(mocks.call.captionSubscriptions.activeCount == 0)
        #expect(mocks.statusDataSource.subscriptions.activeCount == 0)
    }

    @Test("A repeated start preserves a suspended caption write and its worker")
    func repeatedStartWhileCaptionWriteIsSuspended() async throws {
        let (_, mocks) = makeSUT()
        let writer = SuspendedCaptionsWriter()
        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: mocks.statusDataSource, captionsRepository: writer)
        sut.call = mocks.call
        try await sut.callDidStart([:])
        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        mocks.call._captionsPublisher.send(first)
        await writer.waitForFirstWrite()

        // Starting again must not create a second reader while the first write is suspended.
        try await sut.callDidStart([:])
        let captionsCount = mocks.call.captionSubscriptions.activeCount
        let statusCount = mocks.statusDataSource.subscriptions.activeCount
        let second = [CaptionItem(speakerName: "Bob", text: "Second")]
        mocks.call._captionsPublisher.send(second)
        await writer.resumeFirstWrite()
        try await sut.callDidEnd()

        #expect(captionsCount == 1)
        #expect(statusCount == 1)
        let updates = await writer.updates
        #expect(updates.first == first)
        #expect(updates.last == [])
        #expect(await writer.maximumConcurrentWrites == 1)
        #expect(mocks.call.captionSubscriptions.activeCount == 0)
        #expect(mocks.statusDataSource.subscriptions.activeCount == 0)
    }

    // MARK: - Call Did End

    @Test("callDidEnd resets captions status data source")
    func callDidEndResetsStatus() async throws {
        let (sut, mocks) = makeSUT()

        mocks.statusDataSource.set(captionsState: .enabled("captions-123"))
        try await sut.callDidEnd()

        #expect(mocks.statusDataSource.resetCallCount == 1)
    }

    @Test("callDidEnd clears captions in repository")
    func callDidEndClearsCaptions() async throws {
        let (sut, mocks) = makeSUT()

        try await sut.callDidEnd()

        #expect(mocks.repository.updateCallCount == 1)
        #expect(mocks.repository.lastCaptions == [])
    }

    @Test("callDidEnd cancels subscriptions so no more updates are forwarded")
    func callDidEndCancelsSubscriptions() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        let captions = [CaptionItem(speakerName: "Alice", text: "Hello")]
        mocks.call._captionsPublisher.send(captions)
        try await waitUntil { mocks.repository.lastCaptions == captions }

        try await sut.callDidEnd()
        let callCountAfterEnd = mocks.repository.updateCallCount

        // Send more captions after call ended — should be ignored
        mocks.call._captionsPublisher.send([CaptionItem(speakerName: "Bob", text: "Ignored")])
        mocks.statusDataSource.set(captionsState: .enabled("new-id"))

        // Yield to allow any potential (unwanted) updates to process
        await Task.yield()
        await Task.yield()

        // Only the callDidEnd updateCaptions([]) should have been recorded
        #expect(mocks.repository.updateCallCount == callCountAfterEnd)
    }

    // MARK: - Edge Cases

    @Test("callDidEnd then callDidStart re-establishes subscriptions")
    func callDidEndThenCallDidStartReestablishesSubscriptions() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        // First cycle
        try await sut.callDidStart([:])
        mocks.statusDataSource.set(captionsState: .enabled("id-1"))
        try await waitUntil { mocks.call.areCaptionsEnabled }
        try await sut.callDidEnd()

        // After end, enable should not forward
        mocks.statusDataSource.set(captionsState: .enabled("id-2"))
        // Yield to allow any potential (unwanted) updates to process
        await Task.yield()
        await Task.yield()
        #expect(!mocks.call.areCaptionsEnabled)

        // Second cycle — subscriptions should work again
        mocks.call.recordedActions.removeAll()
        try await sut.callDidStart([:])
        mocks.statusDataSource.set(captionsState: .enabled("id-3"))
        try await waitUntil { mocks.call.recordedActions.contains(.enableCaptions) }

        let captions = [CaptionItem(speakerName: "Alice", text: "Back!")]
        mocks.call._captionsPublisher.send(captions)
        try await waitUntil { mocks.repository.lastCaptions == captions }
    }

    @Test("callDidEnd before callDidStart does not throw")
    func callDidEndBeforeCallDidStartDoesNotThrow() async throws {
        let (sut, mocks) = makeSUT()

        try await sut.callDidEnd()

        #expect(mocks.statusDataSource.resetCallCount == 1)
        #expect(mocks.repository.updateCallCount == 1)
        #expect(mocks.repository.lastCaptions == [])
    }

    // MARK: - Helpers

    private struct Mocks {
        let call: MockCallFacade
        let statusDataSource: SpyCaptionsStatusDataSource
        let repository: SpyCaptionsWriter
    }

    private func makeSUT() -> (VonageCaptionsPlugin, Mocks) {
        let statusDataSource = SpyCaptionsStatusDataSource()
        let repository = SpyCaptionsWriter()
        let call = MockCallFacade()

        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: statusDataSource,
            captionsRepository: repository
        )

        let mocks = Mocks(
            call: call,
            statusDataSource: statusDataSource,
            repository: repository
        )

        return (sut, mocks)
    }

    // MARK: - Test Helpers

    /// Allows queued forwarding work to run until the condition holds or the deadline expires.
    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: @escaping @Sendable @MainActor () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while !(await condition()) {
            guard ContinuousClock.now < deadline else { throw WaitTimeoutError() }
            try await Task.sleep(for: .milliseconds(1))
        }
    }

    private struct WaitTimeoutError: Error, CustomStringConvertible {
        var description: String { "waitUntil timed out" }
    }
}

// MARK: - Test Doubles

/// Spy data source that publishes state changes for deterministic testing.
private final class SpyCaptionsStatusDataSource: CaptionsStatusDataSource, @unchecked Sendable {
    nonisolated(unsafe) private let subject = CurrentValueSubject<CaptionsState, Never>(.disabled)

    let subscriptions = SubscriptionCounter()

    nonisolated var captionsState: AnyPublisher<CaptionsState, Never> {
        subject.handleEvents(
            receiveSubscription: { [subscriptions] _ in subscriptions.started() },
            receiveCancel: { [subscriptions] in subscriptions.ended() }
        ).eraseToAnyPublisher()
    }

    nonisolated(unsafe) var resetCallCount = 0

    func set(captionsState: CaptionsState) {
        subject.send(captionsState)
    }

    func reset() {
        resetCallCount += 1
        subject.send(.disabled)
    }
}

/// Spy repository that tracks caption updates for deterministic testing.
private final class SpyCaptionsWriter: CaptionsWriter, @unchecked Sendable {
    nonisolated(unsafe) var updateCallCount = 0
    nonisolated(unsafe) var lastCaptions: [CaptionItem]?
    nonisolated(unsafe) var allUpdates: [[CaptionItem]] = []

    func updateCaptions(_ captions: [CaptionItem]) async {
        updateCallCount += 1
        lastCaptions = captions
        allUpdates.append(captions)
    }
}

/// Mock call facade that publishes events for deterministic testing.
private final class MockCallFacade: CallFacade, @unchecked Sendable {

    nonisolated(unsafe) let _publisherAudioLevelPublisher = CurrentValueSubject<Float, Never>(0.0)
    nonisolated var publisherAudioLevelPublisher: AnyPublisher<Float, Never> {
        _publisherAudioLevelPublisher.eraseToAnyPublisher()
    }

    nonisolated(unsafe) let _networkStatsPublisher = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    nonisolated var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        _networkStatsPublisher.eraseToAnyPublisher()
    }

    nonisolated(unsafe) let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    nonisolated var eventsPublisher: AnyPublisher<SessionEvent, Never> {
        _eventsPublisher.eraseToAnyPublisher()
    }

    nonisolated(unsafe) let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(
        ParticipantsState.empty)
    nonisolated var participantsPublisher: AnyPublisher<ParticipantsState, Never> {
        _participantsPublisher.eraseToAnyPublisher()
    }

    nonisolated(unsafe) let _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    nonisolated var statePublisher: AnyPublisher<SessionState, Never> {
        _statePublisher.eraseToAnyPublisher()
    }

    nonisolated(unsafe) var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    nonisolated var callState: AnyPublisher<CallState, Never> {
        _callState.eraseToAnyPublisher()
    }

    nonisolated(unsafe) var _archivingState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    nonisolated var archivingState: AnyPublisher<ArchivingState, Never> {
        _archivingState.eraseToAnyPublisher()
    }

    nonisolated(unsafe) var _transcriptionState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    nonisolated var transcriptionState: AnyPublisher<ArchivingState, Never> {
        _transcriptionState.eraseToAnyPublisher()
    }

    nonisolated(unsafe) var _captionsPublisher = PassthroughSubject<[CaptionItem], Never>()
    let captionSubscriptions = SubscriptionCounter()

    nonisolated var captionsPublisher: AnyPublisher<[CaptionItem], Never> {
        _captionsPublisher.handleEvents(
            receiveSubscription: { [captionSubscriptions] _ in captionSubscriptions.started() },
            receiveCancel: { [captionSubscriptions] in captionSubscriptions.ended() }
        ).eraseToAnyPublisher()
    }

    nonisolated(unsafe) var recordedActions: [CallActions] = []
    nonisolated(unsafe) var isMuted: Bool = false
    nonisolated(unsafe) var isOnHold: Bool = false
    nonisolated(unsafe) var areCaptionsEnabled = false

    enum CallActions: String {
        case connect, disconnect, toggleLocalVideo, toggleLocalAudio
        case toggleLocalCamera, muteLocalMedia, setOnHold
        case enableCaptions, disableCaptions
    }

    func connect() async throws { recordedActions.append(.connect) }
    func disconnect() async throws { recordedActions.append(.disconnect) }
    func toggleLocalVideo() { recordedActions.append(.toggleLocalVideo) }
    func toggleLocalAudio() { recordedActions.append(.toggleLocalAudio) }
    func toggleLocalCamera() { recordedActions.append(.toggleLocalCamera) }
    func muteLocalMedia(_ isMuted: Bool) {
        self.isMuted = isMuted
        recordedActions.append(.muteLocalMedia)
    }
    func setOnHold(_ isOnHold: Bool) {
        self.isOnHold = isOnHold
        recordedActions.append(.setOnHold)
    }
    func enableCaptions() async {
        areCaptionsEnabled = true
        recordedActions.append(.enableCaptions)
    }
    func disableCaptions() async {
        areCaptionsEnabled = false
        recordedActions.append(.disableCaptions)
    }

    func enableNetworkStats() {}
    func disableNetworkStats() {}
    func enableSubscriberExtraStats() {}
    func disableSubscriberExtraStats() {}

    func applyPublisherAdvancedSettings(_ settings: VERADomain.PublisherAdvancedSettings) async throws {}
    func updateLivePublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async {}
}

/// Counts actual Combine subscription lifetimes, including abandoned readers.
private final class SubscriptionCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var activeCount: Int { lock.withLock { count } }
    func started() { lock.withLock { count += 1 } }
    func ended() { lock.withLock { count -= 1 } }
}

/// Holds the first write open without sleeps so duplicate startup is exercised deterministically.
private actor SuspendedCaptionsWriter: CaptionsWriter {
    private var resume: CheckedContinuation<Void, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private var firstWriteStarted = false
    private var concurrentWrites = 0
    private(set) var maximumConcurrentWrites = 0
    private(set) var updates: [[CaptionItem]] = []

    func updateCaptions(_ captions: [CaptionItem]) async {
        concurrentWrites += 1
        maximumConcurrentWrites = max(maximumConcurrentWrites, concurrentWrites)
        if !firstWriteStarted {
            firstWriteStarted = true
            started?.resume()
            started = nil
            await withCheckedContinuation { resume = $0 }
        }
        updates.append(captions)
        concurrentWrites -= 1
    }

    func waitForFirstWrite() async {
        guard !firstWriteStarted else { return }
        await withCheckedContinuation { started = $0 }
    }

    func resumeFirstWrite() {
        resume?.resume()
        resume = nil
    }
}
