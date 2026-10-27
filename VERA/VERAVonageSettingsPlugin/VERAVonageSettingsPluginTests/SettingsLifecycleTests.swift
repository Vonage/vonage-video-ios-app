import Combine
import Foundation
import Testing
import VERADomain
import VERASettings

@testable import VERAVonageSettingsPlugin

@MainActor
@Suite("Settings observation lifecycle", .timeLimit(.minutes(1)))
struct SettingsLifecycleTests {
    @Test("Repeated startup keeps one set of settings observers")
    func repeatedStartupHasOneObserverSet() async throws {
        let repository = AuditRepository()
        let call = MockCallFacade()
        let sut = VonageSettingsPlugin(settingsRepository: repository, statsWriter: MockStatsWriter())
        sut.call = call
        try await sut.callDidStart([:])
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidStart([:])
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidEnd()
        #expect(repository.subscriptions.activeCount == 0)
    }

    @Test("Teardown before startup is safe and a later call gets one observer set")
    func endBeforeStartAndRestart() async throws {
        let repository = AuditRepository()
        let call = MockCallFacade()
        let sut = VonageSettingsPlugin(settingsRepository: repository, statsWriter: MockStatsWriter())
        sut.call = call
        try await sut.callDidEnd()
        try await sut.callDidEnd()
        try await sut.callDidStart([:])
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidEnd()
        try await sut.callDidStart([:])
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidEnd()
        #expect(repository.subscriptions.activeCount == 0)
    }

    @Test("An old suspended startup cannot apply preferences to a replacement call")
    func oldStartupCannotChangeReplacement() async throws {
        let repository = AuditRepository(blockRead: true)
        let oldCall = MockCallFacade()
        let newCall = MockCallFacade()
        let sut = VonageSettingsPlugin(settingsRepository: repository, statsWriter: MockStatsWriter())
        sut.call = oldCall
        let oldStart = Task { try await sut.callDidStart([:]) }
        await repository.waitForRead()
        try await sut.callDidStart([:])
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidEnd()
        sut.call = newCall
        try await sut.callDidStart([:])
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        let enabledBeforeOldRead = newCall.enableSubscriberExtraStatsCallCount
        await repository.releaseRead()
        try await oldStart.value
        #expect(newCall.enableSubscriberExtraStatsCallCount == enabledBeforeOldRead)
        #expect(repository.subscriptions.activeCount == 3)
        try await sut.callDidEnd()
    }

    @Test("A startup suspended on preferences cannot change SDK state after teardown")
    func lateStartupCannotChangeEndedCall() async throws {
        let repository = AuditRepository(blockRead: true)
        let call = MockCallFacade()
        let sut = VonageSettingsPlugin(settingsRepository: repository, statsWriter: MockStatsWriter())
        sut.call = call
        let start = Task { try await sut.callDidStart([:]) }
        await repository.waitForRead()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        try await sut.callDidEnd()
        let enabledAtEnd = call.enableSubscriberExtraStatsCallCount
        await repository.releaseRead()
        try await start.value
        #expect(call.enableSubscriberExtraStatsCallCount == enabledAtEnd)
    }
}

private actor AuditRepository: PublisherSettingsRepository {
    nonisolated let subscriptions = AuditCounter()
    private nonisolated let relay: CurrentValueRelay<PublisherSettingsPreferences, Never>
    private var blockRead: Bool
    private var readStarted = false
    private var readWaiter: CheckedContinuation<Void, Never>?
    private var suspendedRead: CheckedContinuation<PublisherSettingsPreferences, Never>?
    init(blockRead: Bool = false) {
        self.blockRead = blockRead
        var preferences = PublisherSettingsPreferences.default
        preferences.senderStatsEnabled = true
        relay = CurrentValueRelay(preferences)
    }
    nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        relay.publisher.handleEvents(
            receiveSubscription: { [subscriptions] _ in subscriptions.start() },
            receiveCancel: { [subscriptions] in subscriptions.end() }
        ).eraseToAnyPublisher()
    }
    func getPreferences() async -> PublisherSettingsPreferences {
        if blockRead {
            blockRead = false
            return await withCheckedContinuation { continuation in
                suspendedRead = continuation
                readStarted = true
                readWaiter?.resume()
                readWaiter = nil
            }
        }
        return relay.value
    }
    func waitForRead() async {
        guard !readStarted else { return }
        await withCheckedContinuation { readWaiter = $0 }
    }
    func releaseRead() {
        suspendedRead?.resume(returning: relay.value)
        suspendedRead = nil
    }
    func save(_ preferences: PublisherSettingsPreferences) async throws { relay.send(preferences) }
    func reset() async { relay.send(.default) }
}

/// Test instrumentation only: every count access uses the same synchronous lock.
private final class AuditCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0
    var activeCount: Int { lock.withLock { count } }
    func start() { lock.withLock { count += 1 } }
    func end() { lock.withLock { count -= 1 } }
}
