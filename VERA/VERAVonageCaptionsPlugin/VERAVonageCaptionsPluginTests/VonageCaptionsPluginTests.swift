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
        try await deliver(captions, to: mocks)

        #expect(mocks.repository.lastCaptions == captions)
    }

    @Test("callDidStart forwards multiple caption updates to repository")
    func callDidStartForwardsMultipleUpdates() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        try await deliver(first, to: mocks)

        let countAfterFirst = mocks.repository.updateCallCount

        let second = [
            CaptionItem(speakerName: "Alice", text: "First"),
            CaptionItem(speakerName: "Bob", text: "Second"),
        ]
        try await deliver(second, to: mocks)

        #expect(mocks.repository.updateCallCount > countAfterFirst)
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
        try await deliver(captions, to: mocks)

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
        try await deliver(captions, to: mocks)
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

    /// Waits until the captions forwarding task has subscribed, then until it records `captions`.
    ///
    /// `callDidStart` starts that task without awaiting it, and the test publisher is a
    /// passthrough subject, so a single send before the task subscribes is dropped.
    private func deliver(_ captions: [CaptionItem], to mocks: Mocks) async throws {
        try await waitUntil {
            if mocks.repository.lastCaptions == captions { return true }
            mocks.call._captionsPublisher.send(captions)
            return mocks.repository.lastCaptions == captions
        }
    }

    /// Polls on the main actor long enough for a newly created forwarding task to run.
    private func waitUntil(
        timeout: TimeInterval = 1,
        _ condition: @escaping @Sendable @MainActor () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        if await condition() { return }
        throw WaitTimeoutError()
    }

    private struct WaitTimeoutError: Error, CustomStringConvertible {
        var description: String { "waitUntil timed out" }
    }
}

// MARK: - Test Doubles

/// Spy data source that publishes state changes for deterministic testing.
private final class SpyCaptionsStatusDataSource: CaptionsStatusDataSource, @unchecked Sendable {
    nonisolated(unsafe) private let subject = CurrentValueSubject<CaptionsState, Never>(.disabled)

    nonisolated var captionsState: AnyPublisher<CaptionsState, Never> {
        subject.eraseToAnyPublisher()
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
    nonisolated var captionsPublisher: AnyPublisher<[CaptionItem], Never> {
        _captionsPublisher.eraseToAnyPublisher()
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
