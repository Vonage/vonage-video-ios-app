//
//  Created by Vonage on 16/10/26.
//

import Foundation
import Testing

@testable import VERAVonageCallKitPlugin

@Suite("CallKit mute synchronizer tests")
struct CallKitMuteSynchronizerTests {

    @Test func newCallStartsUnmuted() {
        let sut = CallKitMuteSynchronizer()

        #expect(!sut.shouldReport(isMuted: false))
        #expect(sut.shouldReport(isMuted: true))
    }

    @Test func echoesAreConsumedInRequestOrder() {
        let sut = CallKitMuteSynchronizer()
        _ = sut.shouldReport(isMuted: true)
        _ = sut.shouldReport(isMuted: false)

        #expect(sut.consumeEcho(isMuted: true))
        #expect(sut.consumeEcho(isMuted: false))
        #expect(!sut.consumeEcho(isMuted: true))
    }

    @Test func systemActionUpdatesCallKitState() {
        let sut = CallKitMuteSynchronizer()

        #expect(!sut.consumeEcho(isMuted: true))
        #expect(!sut.shouldReport(isMuted: true))
    }

    @Test func failedReportIsRolledBack() {
        let sut = CallKitMuteSynchronizer()
        _ = sut.shouldReport(isMuted: true)

        sut.reportFailed(isMuted: true)

        #expect(!sut.consumeEcho(isMuted: true))
        #expect(!sut.shouldReport(isMuted: true))
    }

    @Test func failedReportWithoutPendingEchoOnlyRestoresState() {
        let sut = CallKitMuteSynchronizer()

        sut.reportFailed(isMuted: true)

        #expect(sut.shouldReport(isMuted: true))
    }

    @Test func resetClearsStateAndPendingEchoes() {
        let sut = CallKitMuteSynchronizer()
        _ = sut.shouldReport(isMuted: true)

        sut.reset()

        #expect(!sut.shouldReport(isMuted: false))
        #expect(!sut.consumeEcho(isMuted: true))
    }

    @Test func concurrentReportsOfSameValueRequestCallKitOnce() async {
        let sut = CallKitMuteSynchronizer()

        let reportCount = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<1_000 {
                group.addTask { sut.shouldReport(isMuted: true) }
            }
            return await group.reduce(0) { $0 + ($1 ? 1 : 0) }
        }

        #expect(reportCount == 1)
        #expect(sut.consumeEcho(isMuted: true))
        #expect(!sut.consumeEcho(isMuted: true))
    }
}
