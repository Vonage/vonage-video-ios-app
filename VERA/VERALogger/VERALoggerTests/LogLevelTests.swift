//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class LogLevelTests: XCTestCase {

    func testOrdering() {
        XCTAssertTrue(LogLevel.verbose < LogLevel.debug)
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warn)
        XCTAssertTrue(LogLevel.warn < LogLevel.error)
    }

    func testDescriptions() {
        XCTAssertEqual(LogLevel.verbose.description, "VERBOSE")
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warn.description, "WARN")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
    }

    func testAllCases() {
        XCTAssertEqual(LogLevel.allCases.count, 5)
    }
}
