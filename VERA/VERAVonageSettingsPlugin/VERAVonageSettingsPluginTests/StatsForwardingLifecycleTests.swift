//
//  Created by Vonage on 12/10/2026.
//

import Combine
import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@MainActor
@Suite("Statistics forwarding lifecycle", .timeLimit(.minutes(1)))
struct StatsForwardingLifecycleTests {
    @Test("Stop waits for a cancellation-ignoring write before clearing")
    func stopJoinsInFlightWrite() async {
        let writer = ControlledStatsWriter()
        let sut = StatsForwardingLifecycle(writer: writer)
        let source = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        await sut.start(source.eraseToAnyPublisher()).value
        await writer.firstWriteEntered.wait()

        let stop = await sut.stop()
        await writer.firstWriteCancelled.wait()
        await writer.releaseFirstWrite.open()
        await stop.value

        #expect(await writer.actions == ["update:1", "clear"])
    }

    @Test("A new source waits for an old write and clear, even with a cancelled stop caller")
    func newSourceWaitsForTeardown() async {
        let writer = ControlledStatsWriter()
        let sut = StatsForwardingLifecycle(writer: writer)
        let oldSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        let newSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(2))
        await sut.start(oldSource.eraseToAnyPublisher()).value
        await writer.firstWriteEntered.wait()

        let stop = await sut.stop()
        await writer.firstWriteCancelled.wait()
        let start = await sut.start(newSource.eraseToAnyPublisher())
        stop.cancel()
        await writer.releaseFirstWrite.open()
        await stop.value
        await start.value
        await writer.secondWriteCompleted.wait()

        #expect(await writer.actions == ["update:1", "clear", "update:2"])
        await sut.stop().value
    }

    @Test("A new source waits until a suspended clear finishes")
    func newSourceWaitsForInFlightClear() async {
        let writer = ControlledStatsWriter(suspendFirstClear: true)
        await writer.releaseFirstWrite.open()
        let sut = StatsForwardingLifecycle(writer: writer)
        let oldSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        let newSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(2))
        await sut.start(oldSource.eraseToAnyPublisher()).value
        await writer.firstWriteCompleted.wait()

        let stop = await sut.stop()
        await writer.firstClearEntered.wait()
        let start = await sut.start(newSource.eraseToAnyPublisher())
        await writer.releaseFirstClear.open()
        await stop.value
        await start.value
        await writer.secondWriteCompleted.wait()
        #expect(await writer.actions == ["update:1", "clear:start", "clear", "update:2"])
        await sut.stop().value
    }

    @Test("Replacing a source drains the old write and unsubscribes the old source")
    func sourceReplacementDrainsOldForwarding() async {
        let writer = ControlledStatsWriter()
        let sut = StatsForwardingLifecycle(writer: writer)
        let oldSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        let newSource = CurrentValueSubject<NetworkMediaStats, Never>(stats(2))
        await sut.start(oldSource.eraseToAnyPublisher()).value
        await writer.firstWriteEntered.wait()

        let replace = await sut.start(newSource.eraseToAnyPublisher())
        await writer.firstWriteCancelled.wait()
        await writer.releaseFirstWrite.open()
        await replace.value
        await writer.secondWriteCompleted.wait()
        oldSource.send(stats(3))
        await sut.stop().value

        #expect(await writer.actions == ["update:1", "clear", "update:2", "clear"])
    }

    @Test("Concurrent stops queue behind the same pending write")
    func repeatedStopsDoNotClearAheadOfWrite() async {
        let writer = ControlledStatsWriter()
        let sut = StatsForwardingLifecycle(writer: writer)
        let source = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        await sut.start(source.eraseToAnyPublisher()).value
        await writer.firstWriteEntered.wait()
        let firstStop = await sut.stop()
        let secondStop = await sut.stop()
        await writer.firstWriteCancelled.wait()
        await writer.releaseFirstWrite.open()
        await firstStop.value
        await secondStop.value
        #expect(await writer.actions == ["update:1", "clear", "clear"])
    }

    @Test("Stopping without a source is safe")
    func stopWithoutStart() async {
        let writer = ControlledStatsWriter()
        let sut = StatsForwardingLifecycle(writer: writer)
        await sut.stop().value
        #expect(await writer.actions == ["clear"])
    }

    @Test("An idle forwarding task does not retain its lifecycle owner")
    func idleForwardingDoesNotRetainOwner() async {
        let writer = ControlledStatsWriter()
        await writer.releaseFirstWrite.open()
        let source = CurrentValueSubject<NetworkMediaStats, Never>(stats(1))
        var sut: StatsForwardingLifecycle? = StatsForwardingLifecycle(writer: writer)
        weak var owner = sut
        await sut?.start(source.eraseToAnyPublisher()).value
        await writer.firstWriteCompleted.wait()
        sut = nil
        #expect(owner == nil)
        owner = nil
    }

    @Test("Plugin end and subsequent call preserve final clear ordering")
    func pluginEndThenRejoin() async throws {
        let writer = ControlledStatsWriter()
        let firstCall = MockCallFacade()
        let secondCall = MockCallFacade()
        secondCall._networkStatsPublisher.send(stats(2))
        let sut = VonageSettingsPlugin(settingsRepository: MockSettingsRepository(), statsWriter: writer)
        sut.call = firstCall
        try await sut.callDidStart([:])
        await writer.firstWriteEntered.wait()

        let end = Task { try await sut.callDidEnd() }
        await writer.firstWriteCancelled.wait()
        await writer.releaseFirstWrite.open()
        try await end.value
        #expect(await writer.actions == ["update:0", "clear"])

        sut.call = secondCall
        try await sut.callDidStart([:])
        await writer.secondWriteCompleted.wait()
        try await sut.callDidEnd()
        #expect(await writer.actions == ["update:0", "clear", "update:2", "clear"])
    }

    private func stats(_ marker: Int64) -> NetworkMediaStats {
        NetworkMediaStats(
            sentAudio: AudioSendStats(
                packetsSent: 1, packetsLost: 0, bytesSent: marker, timestamp: 1, audioCodec: "opus"
            )
        )
    }
}
