import Foundation
import Testing

@testable import VERAVonage

@Suite("Recovery scheduling")
@MainActor
struct VideoRecoveryTests {
    @Test func coalescesConcurrentFailuresAndResetsBudgetAfterSuccess() async throws {
        let recovery = VideoRecovery()
        var actions = 0
        var delays: [UInt64] = []
        recovery.wait = { delays.append($0) }
        recovery.beginAttempt()
        let error = NSError(domain: "OTSessionErrorDomain", code: 1021)
        try recovery.schedule(policy: .connection, error: error) { actions += 1 }
        try recovery.schedule(policy: .connection, error: error) { actions += 1 }
        for _ in 0..<100 { await Task.yield() }
        #expect(actions == 1)
        #expect(delays == [3_000_000_000])
        recovery.beginAttempt()
        recovery.beginAttempt()
        #expect(throws: VideoRecoveryError.rejected) {
            try recovery.schedule(policy: .connection, error: error) { actions += 1 }
        }
        recovery.reset()
        #expect(recovery.attempts == 0)
    }

    @Test func doesNotRetryPermanentOrForeignDomainErrors() {
        let recovery = VideoRecovery()
        recovery.beginAttempt()
        for error in [
            NSError(domain: "OTSessionErrorDomain", code: 1004),
            NSError(domain: "other", code: 1021), NSError(domain: "OTSessionErrorDomain", code: 9999),
        ] {
            #expect(throws: VideoRecoveryError.rejected) {
                try recovery.schedule(policy: .connection, error: error) { Issue.record("Unexpected retry") }
            }
        }
    }
}
