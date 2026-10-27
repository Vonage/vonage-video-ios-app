import Foundation
import Testing

@testable import VERAVonage

@Suite("Stream lifetime recovery")
@MainActor
struct VideoSubscriptionRecoveryTests {
    @Test func timeoutRetriesThreeTimesWithIncreasingBackoffThenReports() async {
        let recovery = SubscriptionRecovery()
        var attempts = 0
        var errors = 0
        var delays: [UInt64] = []
        recovery.wait = { delays.append($0) }
        recovery.onError = { _ in errors += 1 }
        recovery.add(
            streamID: "stream", isAvailable: { true },
            subscribe: { _ in
                attempts += 1
                throw timeout()
            })
        await settle()
        #expect(attempts == 3)
        #expect(delays == [3_000_000_000, 6_000_000_000])
        #expect(errors == 1)
    }

    @Test func confirmedSubscriberCountsTowardLaterRecoveryBudget() async throws {
        let recovery = SubscriptionRecovery()
        var attempts = 0
        var errors = 0
        var generation: UUID?
        recovery.wait = { _ in }
        recovery.onError = { _ in errors += 1 }
        recovery.add(
            streamID: "stream", isAvailable: { true },
            subscribe: {
                attempts += 1
                generation = $0
                if attempts > 1 { throw timeout() }
            })
        await settle()
        let currentGeneration = try #require(generation)
        recovery.connected(streamID: "stream", generation: currentGeneration)
        recovery.failed(streamID: "stream", generation: currentGeneration, error: timeout())
        await settle()
        #expect(attempts == 3)
        #expect(errors == 1)
    }

    @Test func streamDestructionCancelsRetryEvenWhenWaitDoesNotCooperate() async {
        let recovery = SubscriptionRecovery()
        var resume: CheckedContinuation<Void, Never>?
        var attempts = 0
        recovery.wait = { _ in await withCheckedContinuation { resume = $0 } }
        recovery.add(
            streamID: "stream", isAvailable: { true },
            subscribe: { _ in
                attempts += 1
                throw timeout()
            })
        await settle()
        recovery.remove(streamID: "stream")
        resume?.resume()
        await settle()
        #expect(attempts == 1)
    }

    @Test func checksActualAvailabilityBeforeEveryAttempt() async {
        let recovery = SubscriptionRecovery()
        var isAvailable = true
        var attempts = 0
        recovery.wait = { _ in isAvailable = false }
        recovery.add(
            streamID: "stream", isAvailable: { isAvailable },
            subscribe: { _ in
                attempts += 1
                throw timeout()
            })
        await settle()
        #expect(attempts == 1)
    }

    @Test func duplicateEventsDoNotCreateDuplicateSubscriptions() async {
        let recovery = SubscriptionRecovery()
        var attempts = 0
        for _ in 0..<3 {
            recovery.add(streamID: "stream", isAvailable: { true }, subscribe: { _ in attempts += 1 })
        }
        await settle()
        #expect(attempts == 1)
        recovery.cancelAll()
    }

    @Test func oldGenerationCannotRemoveOrRetryReplacement() async throws {
        let recovery = SubscriptionRecovery()
        var oldGeneration: UUID?
        var attempts = 0
        recovery.add(streamID: "stream", isAvailable: { true }, subscribe: { oldGeneration = $0 })
        await settle()
        recovery.remove(streamID: "stream")
        recovery.add(streamID: "stream", isAvailable: { true }, subscribe: { _ in attempts += 1 })
        await settle()
        recovery.failed(streamID: "stream", generation: try #require(oldGeneration), error: timeout())
        await settle()
        #expect(attempts == 1)
        recovery.cancelAll()
    }

    @Test func permanentAndForeignErrorsAreNotRetried() async {
        for error in [
            NSError(domain: "OTSubscriberErrorDomain", code: 1604),
            NSError(domain: "OTSubscriberErrorDomain", code: 6003),
            NSError(domain: "other", code: 1542),
        ] {
            let recovery = SubscriptionRecovery()
            var attempts = 0
            var errors = 0
            recovery.onError = { _ in errors += 1 }
            recovery.add(
                streamID: "stream", isAvailable: { true },
                subscribe: { _ in
                    attempts += 1
                    throw error
                })
            await settle()
            #expect(attempts == 1)
            #expect(errors == 1)
        }
    }

    @Test func separateStreamsHaveIndependentBudgetsAndCancellation() async {
        let recovery = SubscriptionRecovery()
        var first = 0
        var second = 0
        recovery.wait = { _ in }
        recovery.add(
            streamID: "first", isAvailable: { true },
            subscribe: { _ in
                first += 1
                throw timeout()
            })
        recovery.add(
            streamID: "second", isAvailable: { true },
            subscribe: { _ in
                second += 1
                throw timeout()
            })
        recovery.remove(streamID: "first")
        await settle()
        #expect(first == 0)
        #expect(second == 3)
    }

    @Test func disconnectCancelsEveryStream() async {
        let recovery = SubscriptionRecovery()
        var attempts = 0
        for stream in ["first", "second"] {
            recovery.add(streamID: stream, isAvailable: { true }, subscribe: { _ in attempts += 1 })
        }
        recovery.cancelAll()
        await settle()
        #expect(attempts == 0)
    }

    @Test func confirmedConnectionCancelsPendingRecoveryAndResetsBudget() async throws {
        let recovery = SubscriptionRecovery()
        var attempts = 0
        var generation: UUID?
        recovery.add(
            streamID: "stream", isAvailable: { true },
            subscribe: {
                attempts += 1
                generation = $0
            })
        await settle()
        recovery.failed(streamID: "stream", generation: try #require(generation), error: timeout())
        recovery.connected(streamID: "stream", generation: try #require(generation))
        await settle()
        #expect(attempts == 1)
        recovery.cancelAll()
    }

    private func timeout() -> NSError { NSError(domain: "OTSubscriberErrorDomain", code: 1542) }
    private func settle() async { for _ in 0..<200 { await Task.yield() } }
}
