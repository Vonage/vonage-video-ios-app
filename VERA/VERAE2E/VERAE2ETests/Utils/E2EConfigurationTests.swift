//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import Testing

@testable import VERAE2E

@Suite("E2E configuration tests", .serialized)
struct E2EConfigurationTests {

    @Test("Configuration is enabled when user defaults value is one")
    func configurationIsEnabledWhenUserDefaultsValueIsOne() {
        UserDefaults.standard.set("1", forKey: E2EConfiguration.enabledArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.enabledArgument) }

        #expect(E2EConfiguration.isEnabled)
    }

    @Test("Configuration is disabled when user defaults value is zero")
    func configurationIsDisabledWhenUserDefaultsValueIsZero() {
        UserDefaults.standard.set("0", forKey: E2EConfiguration.enabledArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.enabledArgument) }

        #expect(!E2EConfiguration.isEnabled)
    }

    @Test("Scenario uses default when no value is configured")
    func scenarioUsesDefaultWhenNoValueIsConfigured() {
        UserDefaults.standard.removeObject(forKey: E2EConfiguration.scenarioArgument)
        UserDefaults.standard.removeObject(forKey: E2EConfiguration.forceMuteScenarioArgument)

        #expect(E2EConfiguration.scenario.name == "default")
    }

    @Test(
        "Scenario reads supported values from user defaults",
        arguments: [
            "captions",
            "force-mute",
            "recording",
        ])
    func scenarioReadsSupportedValuesFromUserDefaults(scenarioName: String) {
        UserDefaults.standard.set(scenarioName, forKey: E2EConfiguration.scenarioArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.scenarioArgument) }

        #expect(E2EConfiguration.scenario.name == scenarioName)
    }

    @Test("Scenario uses default for unsupported value")
    func scenarioUsesDefaultForUnsupportedValue() {
        UserDefaults.standard.set("unsupported", forKey: E2EConfiguration.scenarioArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.scenarioArgument) }

        #expect(E2EConfiguration.scenario.name == "default")
    }

    @Test("Scenario keeps force mute fallback for deprecated argument")
    func scenarioKeepsForceMuteFallbackForDeprecatedArgument() {
        UserDefaults.standard.set("1", forKey: E2EConfiguration.forceMuteScenarioArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.forceMuteScenarioArgument) }

        #expect(E2EConfiguration.scenario.name == "force-mute")
    }

    @Test("Failed endpoint reads supported endpoint from user defaults")
    func failedEndpointReadsSupportedEndpointFromUserDefaults() {
        UserDefaults.standard.set(
            E2EEndpoint.searchArchives.rawValue,
            forKey: E2EConfiguration.failEndpointArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.failEndpointArgument) }

        #expect(E2EConfiguration.failedEndpoint == .searchArchives)
    }

    @Test("Failed endpoint ignores unsupported value")
    func failedEndpointIgnoresUnsupportedValue() {
        UserDefaults.standard.set(
            "unsupported",
            forKey: E2EConfiguration.failEndpointArgument)
        defer { UserDefaults.standard.removeObject(forKey: E2EConfiguration.failEndpointArgument) }

        #expect(E2EConfiguration.failedEndpoint == nil)
    }
}
