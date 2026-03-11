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

        #expect(mocks.repository.updateCallCount == 2)
        #expect(mocks.repository.lastCaptions == captions)
    }

    @Test("callDidStart forwards multiple caption updates to repository")
    func callDidStartForwardsMultipleUpdates() async throws {
        let (sut, mocks) = makeSUT()
        sut.call = mocks.call

        try await sut.callDidStart([:])

        let first = [CaptionItem(speakerName: "Alice", text: "First")]
        mocks.call._captionsPublisher.send(first)
        try await waitUntil { mocks.repository.updateCallCount == 2 }

        let second = [
            CaptionItem(speakerName: "Alice", text: "First"),
            CaptionItem(speakerName: "Bob", text: "Second"),
        ]
        mocks.call._captionsPublisher.send(second)
        try await waitUntil { mocks.repository.updateCallCount == 3 }

        #expect(mocks.repository.lastCaptions == second)
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
        try await waitUntil { mocks.repository.updateCallCount == 1 }

        try await sut.callDidEnd()
        let callCountAfterEnd = mocks.repository.updateCallCount

        // Send more captions after call ended — should be ignored
        mocks.call._captionsPublisher.send([CaptionItem(speakerName: "Bob", text: "Ignored")])
        mocks.statusDataSource.set(captionsState: .enabled("new-id"))

        try await Task.sleep(nanoseconds: 100_000_000)

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
        try await Task.sleep(nanoseconds: 50_000_000)
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
}

// MARK: - Test Doubles

private final class SpyCaptionsStatusDataSource: CaptionsStatusDataSource, @unchecked Sendable {
    private let subject = CurrentValueSubject<CaptionsState, Never>(.disabled)

    var captionsState: AnyPublisher<CaptionsState, Never> {
        subject.eraseToAnyPublisher()
    }

    var resetCallCount = 0

    func set(captionsState: CaptionsState) {
        subject.send(captionsState)
    }

    func reset() {
        resetCallCount += 1
        subject.send(.disabled)
    }
}

private final class SpyCaptionsWriter: CaptionsWriter, @unchecked Sendable {
    var updateCallCount = 0
    var lastCaptions: [CaptionItem]?
    var allUpdates: [[CaptionItem]] = []

    func updateCaptions(_ captions: [CaptionItem]) async {
        updateCallCount += 1
        lastCaptions = captions
        allUpdates.append(captions)
    }
}

private final class MockCallFacade: CallFacade, @unchecked Sendable {

    let _networkStatsPublisher = CurrentValueSubject<NetworkMediaStats, Never>(.empty)
    lazy var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> =
        _networkStatsPublisher.eraseToAnyPublisher()

    let _eventsPublisher = CurrentValueSubject<SessionEvent, Never>(.idle)
    lazy var eventsPublisher: AnyPublisher<SessionEvent, Never> = _eventsPublisher.eraseToAnyPublisher()

    let _participantsPublisher = CurrentValueSubject<ParticipantsState, Never>(ParticipantsState.empty)
    lazy var participantsPublisher: AnyPublisher<ParticipantsState, Never> =
        _participantsPublisher.eraseToAnyPublisher()

    let _statePublisher = CurrentValueSubject<SessionState, Never>(SessionState.initial)
    lazy var statePublisher: AnyPublisher<SessionState, Never> = _statePublisher.eraseToAnyPublisher()

    var _callState = CurrentValueSubject<CallState, Never>(CallState.idle)
    lazy var callState: AnyPublisher<CallState, Never> = _callState.eraseToAnyPublisher()

    var _archivingState = CurrentValueSubject<ArchivingState, Never>(ArchivingState.idle)
    lazy var archivingState: AnyPublisher<ArchivingState, Never> = _archivingState.eraseToAnyPublisher()

    var _captionsPublisher = CurrentValueSubject<[CaptionItem], Never>([])
    lazy var captionsPublisher: AnyPublisher<[CaptionItem], Never> = _captionsPublisher.eraseToAnyPublisher()

    var recordedActions: [CallActions] = []
    var isMuted: Bool = false
    var isOnHold: Bool = false
    var areCaptionsEnabled = false

    enum CallActions: String {
        case connect, disconnect, toggleLocalVideo, toggleLocalAudio
        case toggleLocalCamera, muteLocalMedia, setOnHold
        case enableCaptions, disableCaptions
    }

    func connect() { recordedActions.append(.connect) }
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
    func applyPublisherAdvancedSettings(_ settings: VERADomain.PublisherAdvancedSettings) async throws {}
}
