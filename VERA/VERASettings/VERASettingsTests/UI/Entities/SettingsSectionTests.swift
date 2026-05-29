//
//  Created by Vonage on 29/05/2026.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("SettingsSection Tests")
struct SettingsSectionTests {

    @Test("Logging case has correct raw value")
    func loggingRawValue() {
        #expect(SettingsSection.logging.rawValue == "Logging")
    }

    @Test("Logging case is included in allCases")
    func loggingIncludedInAllCases() {
        #expect(SettingsSection.allCases.contains(.logging))
    }

    @Test("Logging icon name is doc.text")
    func loggingIconName() {
        #expect(SettingsSection.logging.iconName == "doc.text")
    }

    @Test("All sections have non-empty icon names")
    func allSectionsHaveIconNames() {
        for section in SettingsSection.allCases {
            #expect(!section.iconName.isEmpty)
        }
    }

    @Test("All sections have non-empty display names")
    func allSectionsHaveDisplayNames() {
        for section in SettingsSection.allCases {
            #expect(!section.displayName.isEmpty)
        }
    }

    @Test("Identifiable id returns self")
    func identifiableIdReturnsSelf() {
        for section in SettingsSection.allCases {
            #expect(section.id == section)
        }
    }

    @Test("Each section has a unique icon name")
    func eachSectionHasUniqueIconName() {
        let iconNames = SettingsSection.allCases.map(\.iconName)
        #expect(Set(iconNames).count == iconNames.count)
    }
}
