//
//  Created by Vonage on 29/05/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("SDKLoggingPreferences Tests")
struct SDKLoggingPreferencesTests {

    @Test("Default initializer uses expected defaults")
    func defaultInitializerUsesExpectedDefaults() {
        let prefs = SDKLoggingPreferences()

        #expect(prefs.isLoggingEnabled == false)
        #expect(prefs.logLevel == .debug)
        #expect(prefs.pendingLogCleanup == false)
    }

    @Test("Static default matches parameterless init")
    func staticDefaultMatchesInit() {
        #expect(SDKLoggingPreferences.default == SDKLoggingPreferences())
    }

    @Test("Custom initializer stores all values")
    func customInitializerStoresAllValues() {
        let prefs = SDKLoggingPreferences(
            isLoggingEnabled: true,
            logLevel: .error,
            pendingLogCleanup: true
        )

        #expect(prefs.isLoggingEnabled == true)
        #expect(prefs.logLevel == .error)
        #expect(prefs.pendingLogCleanup == true)
    }

    @Test("Equatable detects differences in isLoggingEnabled")
    func equatableDetectsLoggingEnabledDifference() {
        let a = SDKLoggingPreferences(isLoggingEnabled: false)
        let b = SDKLoggingPreferences(isLoggingEnabled: true)

        #expect(a != b)
    }

    @Test("Equatable detects differences in logLevel")
    func equatableDetectsLogLevelDifference() {
        let a = SDKLoggingPreferences(logLevel: .debug)
        let b = SDKLoggingPreferences(logLevel: .error)

        #expect(a != b)
    }

    @Test("Equatable detects differences in pendingLogCleanup")
    func equatableDetectsPendingCleanupDifference() {
        let a = SDKLoggingPreferences(pendingLogCleanup: false)
        let b = SDKLoggingPreferences(pendingLogCleanup: true)

        #expect(a != b)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let original = SDKLoggingPreferences(
            isLoggingEnabled: true,
            logLevel: .warn,
            pendingLogCleanup: true
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SDKLoggingPreferences.self, from: data)

        #expect(decoded == original)
    }

    @Test("Codable round-trip preserves default values")
    func codableRoundTripDefaults() throws {
        let original = SDKLoggingPreferences()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SDKLoggingPreferences.self, from: data)

        #expect(decoded == original)
    }
}
