//
//  Created by Vonage on 29/05/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("SDKLogLevel Tests")
struct SDKLogLevelTests {

    @Test("All cases have correct raw values")
    func allCasesHaveCorrectRawValues() {
        #expect(SDKLogLevel.verbose.rawValue == 0)
        #expect(SDKLogLevel.debug.rawValue == 1)
        #expect(SDKLogLevel.info.rawValue == 2)
        #expect(SDKLogLevel.warn.rawValue == 3)
        #expect(SDKLogLevel.error.rawValue == 4)
    }

    @Test("allCases returns all five levels")
    func allCasesReturnsAllLevels() {
        #expect(SDKLogLevel.allCases.count == 5)
        #expect(SDKLogLevel.allCases == [.verbose, .debug, .info, .warn, .error])
    }

    @Test(
        "description returns uppercase string",
        arguments: [
            (SDKLogLevel.verbose, "VERBOSE"),
            (.debug, "DEBUG"),
            (.info, "INFO"),
            (.warn, "WARN"),
            (.error, "ERROR"),
        ])
    func descriptionReturnsUppercaseString(level: SDKLogLevel, expected: String) {
        #expect(level.description == expected)
    }

    @Test("Identifiable id returns self")
    func identifiableIdReturnsSelf() {
        for level in SDKLogLevel.allCases {
            #expect(level.id == level)
        }
    }

    @Test("Comparable orders by raw value")
    func comparableOrdersByRawValue() {
        #expect(SDKLogLevel.verbose < .debug)
        #expect(SDKLogLevel.debug < .info)
        #expect(SDKLogLevel.info < .warn)
        #expect(SDKLogLevel.warn < .error)
        #expect(!(SDKLogLevel.error < .verbose))
    }

    @Test("Codable round-trip preserves value", arguments: SDKLogLevel.allCases)
    func codableRoundTrip(level: SDKLogLevel) throws {
        let data = try JSONEncoder().encode(level)
        let decoded = try JSONDecoder().decode(SDKLogLevel.self, from: data)
        #expect(decoded == level)
    }

    @Test("displayName is non-empty for all cases")
    func displayNameIsNonEmpty() {
        for level in SDKLogLevel.allCases {
            #expect(!level.displayName.isEmpty)
        }
    }
}
