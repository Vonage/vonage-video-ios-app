//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LogEvent Tests")
struct LogEventTests {

    @Test("Default timestamp is set to now and thread is non-empty")
    func defaultTimestampAndThread() {
        let before = Date()
        let event = LogEvent(level: .debug, tag: "T", message: "msg")
        let after = Date()

        #expect(event.timestamp >= before)
        #expect(event.timestamp <= after)
        #expect(!event.thread.isEmpty)
    }

    @Test("Copy overrides specified fields")
    func copyOverridesFields() {
        let event = LogEvent(level: .debug, tag: "Original", message: "msg")
        let copied = event.copy(tag: "Changed", message: "new msg")

        #expect(copied.tag == "Changed")
        #expect(copied.message == "new msg")
        #expect(copied.level == .debug)
    }

    @Test("Copy preserves unchanged fields")
    func copyPreservesUnchangedFields() {
        let error = NSError(domain: "test", code: 1)
        let event = LogEvent(
            level: .error,
            tag: "T",
            message: "msg",
            error: error,
            timestamp: Date(timeIntervalSince1970: 1000),
            thread: "mythread"
        )
        let copied = event.copy(level: .warn)

        #expect(copied.level == .warn)
        #expect(copied.tag == "T")
        #expect(copied.message == "msg")
        #expect(copied.error != nil)
        #expect(copied.timestamp == Date(timeIntervalSince1970: 1000))
        #expect(copied.thread == "mythread")
    }

    @Test("Error defaults to nil")
    func nilErrorDefault() {
        let event = LogEvent(level: .info, tag: "T", message: "msg")
        #expect(event.error == nil)
    }
}
