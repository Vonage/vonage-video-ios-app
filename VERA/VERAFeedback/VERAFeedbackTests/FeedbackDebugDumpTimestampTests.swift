//
//  Created by Vonage on 15/10/26.
//

import Foundation
import Testing

@testable import VERAFeedback

@Suite("Feedback diagnostic timestamps")
struct FeedbackDebugDumpTimestampTests {
    @Test("Connection timestamps keep UTC milliseconds", arguments: [0.0, -1.0, 1_700_000_000.125])
    @MainActor
    func timestampsKeepExistingFormat(timestamp: TimeInterval) {
        let expected: String
        switch timestamp {
        case 0: expected = "1970-01-01T00:00:00.000Z"
        case -1: expected = "1969-12-31T23:59:59.000Z"
        default: expected = "2023-11-14T22:13:20.125Z"
        }
        let dump = FeedbackDebugDumpBuilder.debugDump(
            session: FeedbackSessionDebugInfo(connectionCreationTime: Date(timeIntervalSince1970: timestamp))
        )

        #expect(dump.contains("Connection creation time: \(expected)"))
    }

    #if os(macOS)
        @Test("Concurrent dumps keep each session and its own timestamp")
        func concurrentDumpsRetainPerSessionTimestamps() async {
            await withTaskGroup(of: (Int, String).self) { group in
                for index in 0..<64 {
                    group.addTask {
                        let session = FeedbackSessionDebugInfo(
                            sessionId: "session-\(index)",
                            connectionId: "connection-\(index)",
                            connectionCreationTime: Date(timeIntervalSince1970: Double(index) + 0.125)
                        )
                        return (index, FeedbackDebugDumpBuilder.debugDump(session: session))
                    }
                }

                var received = Set<Int>()
                for await (index, dump) in group {
                    let expected = String(format: "1970-01-01T00:%02d:%02d.125Z", index / 60, index % 60)
                    #expect(dump.contains("Session: session-\(index)\n"))
                    #expect(dump.contains("Connection: connection-\(index)\n"))
                    #expect(dump.contains("Connection creation time: \(expected)"))
                    received.insert(index)
                }
                #expect(received.count == 64)
            }
        }
    #endif
}
