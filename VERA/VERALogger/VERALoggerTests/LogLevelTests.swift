//
//  Created by Vonage on 8/4/26.
//

import Testing

@testable import VERALogger

@Suite("LogLevel Tests")
struct LogLevelTests {

    @Test("Levels are ordered from verbose to error")
    func ordering() {
        #expect(LogLevel.verbose < LogLevel.debug)
        #expect(LogLevel.debug < LogLevel.info)
        #expect(LogLevel.info < LogLevel.warn)
        #expect(LogLevel.warn < LogLevel.error)
    }

    @Test(
        "Each level has the correct description",
        arguments: [
            (LogLevel.verbose, "VERBOSE"),
            (LogLevel.debug, "DEBUG"),
            (LogLevel.info, "INFO"),
            (LogLevel.warn, "WARN"),
            (LogLevel.error, "ERROR"),
        ]
    )
    func descriptions(testCase: (LogLevel, String)) {
        let (level, expected) = testCase
        #expect(level.description == expected)
    }

    @Test("All cases count is 5")
    func allCases() {
        #expect(LogLevel.allCases.count == 5)
    }
}
