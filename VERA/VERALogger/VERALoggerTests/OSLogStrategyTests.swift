//
//  Created by Vonage on 8/5/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("OSLogStrategy Tests")
struct OSLogStrategyTests {

    @Test(
        "Routes each level to the matching OS logger method",
        arguments: [
            (LogLevel.verbose, OSLoggerSpy.Call.trace),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    fileprivate func routesLogLevelToExpectedOSMethod(level: LogLevel, expectedCall: OSLoggerSpy.Call) {
        let spy = OSLoggerSpy()
        let sut = OSLogStrategy(logger: spy)

        sut.log(LogEvent(level: level, tag: "Tag", message: "Message"))

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.call == expectedCall)
        #expect(spy.calls.first?.message == "[Tag] Message")
    }

    @Test("Includes error details in the formatted message")
    func includesErrorInFormattedMessage() {
        let spy = OSLoggerSpy()
        let sut = OSLogStrategy(logger: spy)

        sut.log(
            LogEvent(
                level: .error,
                tag: "Tag",
                message: "Message",
                error: TestError(),
            )
        )

        #expect(spy.calls.count == 1)
        #expect(spy.calls.first?.call == .error)
        #expect(spy.calls.first?.message == "[Tag] Message\nboom")
    }
}

private struct TestError: Error, CustomStringConvertible {
    var description: String { "boom" }
}

private final class OSLoggerSpy: OSLoggerType, @unchecked Sendable {

    enum Call: Equatable {
        case trace
        case debug
        case info
        case warning
        case error
    }

    struct Entry: Equatable {
        let call: Call
        let message: String
    }

    private var callsStorage: [Entry] = []
    private let lock = NSLock()

    var calls: [Entry] {
        lock.withLock { callsStorage }
    }

    func trace(_ message: String) {
        lock.withLock {
            callsStorage.append(.init(call: .trace, message: message))
        }
    }

    func debug(_ message: String) {
        lock.withLock {
            callsStorage.append(.init(call: .debug, message: message))
        }
    }

    func info(_ message: String) {
        lock.withLock {
            callsStorage.append(.init(call: .info, message: message))
        }
    }

    func warning(_ message: String) {
        lock.withLock {
            callsStorage.append(.init(call: .warning, message: message))
        }
    }

    func error(_ message: String) {
        lock.withLock {
            callsStorage.append(.init(call: .error, message: message))
        }
    }
}
