//
//  Created by Vonage on 16/10/2026.
//

import Combine
import Foundation
import Testing
import VERADomain
import VERAVonage

@testable import VERAE2E

@MainActor
@Suite("E2E plugin lifecycle ordering")
struct E2ECallLifecycleTests {
    @Test("Archiving notifications posted off the main actor preserve start and stop state")
    func backgroundArchivingNotifications() async throws {
        let call = E2ECallFacade()
        let started = AsyncStream<Void>.makeStream()
        let stopped = AsyncStream<Void>.makeStream()
        var states: [ArchivingState] = []
        let observation = call.archivingState.sink { state in
            states.append(state)
            if state == .archiving("background-archive") { started.continuation.yield(()) }
            if state == .idle && states.count > 1 { stopped.continuation.yield(()) }
        }
        defer { observation.cancel() }

        await Task.detached {
            NotificationCenter.default.post(name: E2EArchivingEvents.didStart, object: "background-archive")
        }.value
        let didStart = await waitForLifecycleEvent(started.stream)
        #expect(didStart)

        await Task.detached {
            NotificationCenter.default.post(name: E2EArchivingEvents.didStop, object: nil)
        }.value
        let didStop = await waitForLifecycleEvent(stopped.stream)
        #expect(didStop)
        #expect(states == [.idle, .archiving("background-archive"), .idle])
    }

    @Test("Disconnect joins canceled initialization before ending or unassigning any plugin")
    func disconnectWaitsForPluginInitialization() async throws {
        let journal = PluginLifecycleJournal()
        let first = LifecyclePluginSpy(id: "first", journal: journal, blocksStart: true)
        let second = LifecyclePluginSpy(id: "second", journal: journal)
        defer { first.resumeStart() }
        let call = E2ECallFacade(plugins: [first, second])
        var states: [CallState] = []
        let observation = call.callState.sink { states.append($0) }
        defer { observation.cancel() }

        try await call.connect()
        let started = await waitForLifecycleEvent(first.didBeginStart)
        try #require(started)
        let teardown = Task { try await call.disconnect() }
        let canceled = await waitForLifecycleEvent(first.didCancelStart)
        #expect(canceled)
        #expect(journal.events == ["first.start"])
        #expect(first.call != nil)
        #expect(states.last == .disconnecting)

        // A duplicate disconnect must share teardown rather than ending plugins early.
        let duplicateTeardown = Task { try await call.disconnect() }
        first.resumeStart()
        try await teardown.value
        try await duplicateTeardown.value

        #expect(journal.events == ["first.start", "first.started", "first.end", "second.end"])
        #expect(first.callWasAssignedAtEnd)
        #expect(second.callWasAssignedAtEnd)
        #expect(first.call == nil)
        #expect(second.call == nil)
        #expect(states == [.idle, .connecting, .connected, .disconnecting, .disconnected])
    }

    @Test("Repeated connection and teardown requests preserve one linear call lifecycle")
    func duplicateRequestsDoNotRestartPluginsAfterTeardown() async throws {
        let journal = PluginLifecycleJournal()
        let plugin = LifecyclePluginSpy(id: "plugin", journal: journal)
        let call = E2ECallFacade(plugins: [plugin])
        var states: [CallState] = []
        let observation = call.callState.sink { states.append($0) }
        defer { observation.cancel() }

        try await call.connect()
        try await call.connect()
        try await call.disconnect()
        try await call.disconnect()
        await Task.yield()

        #expect(journal.events.filter { $0 == "plugin.end" }.count == 1)
        #expect(journal.events.last == "plugin.end")
        #expect(plugin.call == nil)
        #expect(states == [.idle, .connecting, .connected, .disconnecting, .disconnected])
    }
}

@MainActor
private final class PluginLifecycleJournal {
    var events: [String] = []
}

@MainActor
private final class LifecyclePluginSpy: VonagePlugin, VonagePluginCallHolder {
    let pluginIdentifier: String
    weak var call: (any CallFacade)?
    private let journal: PluginLifecycleJournal
    private let blocksStart: Bool
    private var startContinuation: CheckedContinuation<Void, Never>?
    private let beganContinuation: AsyncStream<Void>.Continuation
    private let canceledContinuation: AsyncStream<Void>.Continuation
    let didBeginStart: AsyncStream<Void>
    let didCancelStart: AsyncStream<Void>
    private(set) var callWasAssignedAtEnd = false

    init(id: String, journal: PluginLifecycleJournal, blocksStart: Bool = false) {
        pluginIdentifier = id
        self.journal = journal
        self.blocksStart = blocksStart
        let began = AsyncStream<Void>.makeStream()
        didBeginStart = began.stream
        beganContinuation = began.continuation
        let canceled = AsyncStream<Void>.makeStream()
        didCancelStart = canceled.stream
        canceledContinuation = canceled.continuation
    }

    func callDidStart(_ userInfo: [String: Any]) async throws {
        journal.events.append("\(pluginIdentifier).start")
        beganContinuation.yield(())
        if blocksStart {
            let canceled = canceledContinuation
            await withTaskCancellationHandler {
                // Deliberately ignore cancellation until the underlying operation completes.
                await withCheckedContinuation { startContinuation = $0 }
            } onCancel: {
                canceled.yield(())
            }
        }
        journal.events.append("\(pluginIdentifier).started")
    }

    func callDidEnd() async throws {
        callWasAssignedAtEnd = call != nil
        journal.events.append("\(pluginIdentifier).end")
    }

    func resumeStart() {
        let continuation = startContinuation
        startContinuation = nil
        continuation?.resume()
    }
}

private func waitForLifecycleEvent(_ events: AsyncStream<Void>) async -> Bool {
    await withTaskGroup(of: Bool.self) { group in
        group.addTask {
            for await _ in events { return true }
            return false
        }
        group.addTask {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return false
        }
        let result = await group.next() ?? false
        group.cancelAll()
        return result
    }
}
