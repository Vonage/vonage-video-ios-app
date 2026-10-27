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

    @Test("Background delivery enters actor workers without inheriting UI isolation")
    func acceptsBackgroundCaptionAndActivationPublishers() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call
        try await sut.callDidStart([:])
        let source = mocks.statusDataSource
        let captionRelay = mocks.call._captionsPublisher
        let captions = [CaptionItem(speakerName: "Alice", text: "Background delivery")]

        await Task.detached {
            source.set(captionsState: .enabled("background"))
            captionRelay.send(captions)
        }.value
        try await waitUntil {
            mocks.call.areCaptionsEnabled && mocks.repository.lastCaptions == captions
        }

        #expect(mocks.repository.lastCaptions == captions)
        #expect(mocks.call.areCaptionsEnabled)
        try await sut.callDidEnd()
    }

    @Test("Repeated starts keep one live subscription pair")
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

    @Test("Restart joins an in-flight write before installing replacement observers", .timeLimit(.minutes(1)))
    func repeatedStartWhileCaptionWriteIsSuspended() async throws {
        let (_, mocks) = makeSUT()
        let writer = BlockingCaptionsWriter()
        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: mocks.statusDataSource, captionsRepository: writer)
        sut.call = mocks.call
        try await sut.callDidStart([:])
        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        mocks.call._captionsPublisher.send(first)
        await writer.waitForBlockedWrite()
        let restart = Task { try await sut.callDidStart([:]) }
        await writer.waitForCancellation()
        #expect(mocks.call.captionSubscriptions.activeCount == 0)
        #expect(mocks.statusDataSource.subscriptions.activeCount == 0)
        await writer.releaseBlockedWrite()
        try await restart.value
        #expect(mocks.call.captionSubscriptions.activeCount == 1)
        #expect(mocks.statusDataSource.subscriptions.activeCount == 1)
        let second = [CaptionItem(speakerName: "Bob", text: "Second")]
        mocks.call._captionsPublisher.send(second)
        await writer.waitForUpdates(2)
        try await sut.callDidEnd()
        #expect(await writer.updates == [first, second, []])
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

    @Test("A slow caption writer retains only the newest pending snapshot", .timeLimit(.minutes(1)))
    func coalescesPendingSnapshotsWithoutConcurrentWrites() async throws {
        let writer = BlockingCaptionsWriter()
        let call = MockCallFacade()
        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: SpyCaptionsStatusDataSource(), captionsRepository: writer)
        sut.call = call
        try await sut.callDidStart([:])
        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        let newest = [CaptionItem(speakerName: "Alice", text: "Newest")]
        call._captionsPublisher.send(first)
        await writer.waitForBlockedWrite()

        for index in 0..<100 {
            call._captionsPublisher.send([CaptionItem(speakerName: "Alice", text: "Pending \(index)")])
        }
        call._captionsPublisher.send(newest)
        await writer.releaseBlockedWrite()
        await writer.waitForUpdates(2)

        #expect(await writer.updates == [first, newest])
        #expect(await writer.maximumConcurrentWrites == 1)
        try await sut.callDidEnd()
        #expect(await writer.updates == [first, newest, []])
    }

    @Test("Teardown joins an in-flight caption write before clearing", .timeLimit(.minutes(1)))
    func joinsInFlightWriteBeforeFinalClear() async throws {
        let writer = BlockingCaptionsWriter()
        let call = MockCallFacade()
        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: SpyCaptionsStatusDataSource(), captionsRepository: writer)
        sut.call = call
        try await sut.callDidStart([:])
        let first = [CaptionItem(speakerName: "Alice", text: "Writing")]
        call._captionsPublisher.send(first)
        await writer.waitForBlockedWrite()
        call._captionsPublisher.send([CaptionItem(speakerName: "Alice", text: "Queued")])

        let ending = Task { try await sut.callDidEnd() }
        await writer.waitForCancellation()
        #expect(await writer.updates.isEmpty)
        call._captionsPublisher.send([CaptionItem(speakerName: "Alice", text: "After cancellation")])
        await writer.releaseBlockedWrite()
        try await ending.value

        #expect(await writer.updates == [first, []])
        #expect(await writer.maximumConcurrentWrites == 1)
    }

    @Test("Finishing an old call does not disable its replacement", .timeLimit(.minutes(1)))
    func teardownUsesItsOriginalCallAfterSuspension() async throws {
        let writer = BlockingCaptionsWriter()
        let oldCall = MockCallFacade()
        let newCall = MockCallFacade()
        let sut = VonageCaptionsPlugin(
            captionsStatusDataSource: SpyCaptionsStatusDataSource(), captionsRepository: writer)
        sut.call = oldCall
        try await sut.callDidStart([:])
        oldCall._captionsPublisher.send([CaptionItem(speakerName: "Old room", text: "Writing")])
        await writer.waitForBlockedWrite()
        let ending = Task { try await sut.callDidEnd() }
        await writer.waitForCancellation()
        oldCall.areCaptionsEnabled = true
        newCall.areCaptionsEnabled = true
        sut.call = newCall

        await writer.releaseBlockedWrite()
        try await ending.value

        #expect(!oldCall.areCaptionsEnabled)
        #expect(newCall.areCaptionsEnabled)
        #expect(newCall.recordedActions.isEmpty)
    }

    @Test("Running observers do not retain the plugin")
    func releasesPluginWhileObserversAreRunning() async throws {
        let source = SpyCaptionsStatusDataSource()
        let repository = SpyCaptionsWriter()
        let call = MockCallFacade()
        var plugin: VonageCaptionsPlugin? = VonageCaptionsPlugin(
            captionsStatusDataSource: source, captionsRepository: repository)
        plugin?.call = call
        try await plugin?.callDidStart([:])
        weak var releasedPlugin = plugin

        plugin = nil

        #expect(releasedPlugin == nil)
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
    private let subject = CurrentValueRelay<CaptionsState, Never>(.disabled)
    private let lock = NSLock()
    private var resets = 0

    let subscriptions = SubscriptionCounter()

    var captionsState: AnyPublisher<CaptionsState, Never> {
        subject.publisher.handleEvents(
            receiveSubscription: { [subscriptions] _ in subscriptions.started() },
            receiveCancel: { [subscriptions] in subscriptions.ended() }
        ).eraseToAnyPublisher()
    }

    var resetCallCount: Int { lock.withLock { resets } }

    func set(captionsState: CaptionsState) {
        subject.send(captionsState)
    }

    func reset() {
        lock.withLock { resets += 1 }
        subject.send(.disabled)
    }
}

/// Spy repository that tracks caption updates for deterministic testing.
@MainActor
private final class SpyCaptionsWriter: CaptionsWriter {
    var updateCallCount = 0
    var lastCaptions: [CaptionItem]?
    var allUpdates: [[CaptionItem]] = []

    func updateCaptions(_ captions: [CaptionItem]) async {
        updateCallCount += 1
        lastCaptions = captions
        allUpdates.append(captions)
    }
}

/// Mock call facade that publishes events for deterministic testing.
private final class MockCallFacade: CallFacade {

    let _publisherAudioLevelPublisher = CurrentValueSubject<Float, Never>(0.0)
    var publisherAudioLevelPublisher: AnyPublisher<Float, Never> {
        _publisherAudioLevelPublisher.eraseToAnyPublisher()
    }

    let _networkStatsPublisher = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        _networkStatsPublisher.eraseToAnyPublisher()
    }

    let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    var eventsPublisher: AnyPublisher<SessionEvent, Never> {
        _eventsPublisher.eraseToAnyPublisher()
    }

    let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(
        ParticipantsState.empty)
    var participantsPublisher: AnyPublisher<ParticipantsState, Never> {
        _participantsPublisher.eraseToAnyPublisher()
    }

    let _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    var statePublisher: AnyPublisher<SessionState, Never> {
        _statePublisher.eraseToAnyPublisher()
    }

    var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    var callState: AnyPublisher<CallState, Never> {
        _callState.eraseToAnyPublisher()
    }

    var _archivingState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    var archivingState: AnyPublisher<ArchivingState, Never> {
        _archivingState.eraseToAnyPublisher()
    }

    var _transcriptionState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    var transcriptionState: AnyPublisher<ArchivingState, Never> {
        _transcriptionState.eraseToAnyPublisher()
    }

    let _captionsPublisher = EventRelay<[CaptionItem], Never>()
    let captionSubscriptions = SubscriptionCounter()

    var captionsPublisher: AnyPublisher<[CaptionItem], Never> {
        _captionsPublisher.publisher.handleEvents(
            receiveSubscription: { [captionSubscriptions] _ in captionSubscriptions.started() },
            receiveCancel: { [captionSubscriptions] in captionSubscriptions.ended() }
        ).eraseToAnyPublisher()
    }

    var recordedActions: [CallActions] = []
    var isMuted: Bool = false
    var isOnHold: Bool = false
    var areCaptionsEnabled = false

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


/// Suspends the first write to exercise stream backpressure without timing assumptions.
private actor BlockingCaptionsWriter: CaptionsWriter {
    private(set) var updates: [[CaptionItem]] = []
    private(set) var maximumConcurrentWrites = 0
    private var activeWrites = 0
    private let cancellations = AsyncStream<Void>.makeStream()
    private var hasBlocked = false
    private var blockedWrite: CheckedContinuation<Void, Never>?
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var updateWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func updateCaptions(_ captions: [CaptionItem]) async {
        activeWrites += 1
        maximumConcurrentWrites = max(maximumConcurrentWrites, activeWrites)
        if !hasBlocked {
            hasBlocked = true
            let cancellation = cancellations.continuation
            await withTaskCancellationHandler {
                await withCheckedContinuation { continuation in
                    blockedWrite = continuation
                    for waiter in blockedWaiters {
                        waiter.resume()
                    }
                    blockedWaiters.removeAll()
                }
            } onCancel: {
                cancellation.yield(())
            }
        }
        updates.append(captions)
        activeWrites -= 1
        let ready = updateWaiters.filter { $0.0 <= updates.count }
        updateWaiters.removeAll { $0.0 <= updates.count }
        for (_, waiter) in ready {
            waiter.resume()
        }
    }

    func waitForBlockedWrite() async {
        guard blockedWrite == nil else { return }
        await withCheckedContinuation { blockedWaiters.append($0) }
    }

    func waitForCancellation() async {
        for await _ in cancellations.stream { return }
    }

    func releaseBlockedWrite() {
        blockedWrite?.resume()
        blockedWrite = nil
    }

    func waitForUpdates(_ count: Int) async {
        guard updates.count < count else { return }
        await withCheckedContinuation { updateWaiters.append((count, $0)) }
    }
}

/// Tracks actual Combine subscription lifetimes across repeated lifecycle notifications.
private final class SubscriptionCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var activeCount: Int { lock.withLock { count } }
    func started() { lock.withLock { count += 1 } }
    func ended() { lock.withLock { count -= 1 } }
}
