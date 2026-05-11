//
//  Created by Vonage on 11/5/26.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("SettingsBackgroundProvider tests")
struct SettingsBackgroundProviderTests {

    @Test
    func rawValuesMatchDomainEnum() {
        // The Settings enum and the VERABackgroundEffects enum share raw values
        // so the bridging adapter can use `init(rawValue:)` directly.
        #expect(SettingsBackgroundProvider.vonage.rawValue == 1)
        #expect(SettingsBackgroundProvider.appleVision.rawValue == 2)
    }

    @Test
    func allCasesEnumeratesBoth() {
        #expect(SettingsBackgroundProvider.allCases == [.vonage, .appleVision])
    }

    @Test
    func idEqualsRawValue() {
        #expect(SettingsBackgroundProvider.vonage.id == 1)
        #expect(SettingsBackgroundProvider.appleVision.id == 2)
    }

    @Test(arguments: [
        (SettingsBackgroundProvider.vonage, "Vonage"),
        (SettingsBackgroundProvider.appleVision, "Apple Vision"),
    ])
    func displayNameForEachCase(value: SettingsBackgroundProvider, expected: String) {
        #expect(value.displayName == expected)
    }

    @Test
    func codableRoundTrip() throws {
        let original = SettingsBackgroundProvider.appleVision
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SettingsBackgroundProvider.self, from: encoded)
        #expect(decoded == original)
    }
}
