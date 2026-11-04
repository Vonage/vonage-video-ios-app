//
//  Created by Vonage on 21/10/26.
//

import Foundation
import Testing

@testable import VERASettings

@Suite("Captions translation preference")
@MainActor
struct CaptionsTranslationPreferenceTests {
    @Test("Preferences saved before the feature decode to the original language")
    func legacyPayloadDecodesToOriginal() throws {
        let legacy = try JSONEncoder().encode(PublisherSettingsPreferences.default)
        #expect(!String(decoding: legacy, as: UTF8.self).contains("captionsTranslationLanguage"))

        let decoded = try JSONDecoder().decode(PublisherSettingsPreferences.self, from: legacy)

        #expect(decoded.captionsTranslationLanguage == nil)
        #expect(decoded == .default)
    }

    @Test("A selected language round-trips and participates in equality")
    func selectedLanguageRoundTrips() throws {
        let preferences = PublisherSettingsPreferences(captionsTranslationLanguage: "es-ES")

        let decoded = try JSONDecoder().decode(
            PublisherSettingsPreferences.self, from: JSONEncoder().encode(preferences))

        #expect(decoded.captionsTranslationLanguage == "es-ES")
        #expect(decoded != .default)
    }

    @Test("The language list mirrors the 49 Web VERA codes without duplicates")
    func languageListMatchesWeb() {
        let codes = CaptionsTranslationLanguage.supportedCodes

        #expect(codes.count == 49)
        #expect(Set(codes).count == codes.count)
        #expect(Set(CaptionsTranslationLanguage.options(locale: Locale(identifier: "en")).map(\.code)) == Set(codes))
        #expect(
            CaptionsTranslationLanguage.displayName(for: "es-ES", locale: Locale(identifier: "en")) == "Spanish (Spain)"
        )
    }

    @Test("Picker options are sorted by name and the current-locale list is built once")
    func optionsAreSortedAndCached() {
        let locale = Locale(identifier: "en")
        let options = CaptionsTranslationLanguage.options(locale: locale)
        let names = options.map(\.name)

        #expect(options.count == CaptionsTranslationLanguage.supportedCodes.count)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(
            options.allSatisfy {
                $0.name == CaptionsTranslationLanguage.displayName(for: $0.code, locale: locale)
            })
        #expect(CaptionsTranslationLanguage.currentLocaleOptions == CaptionsTranslationLanguage.options())
    }

    @Test(
        "Every supported code has a capitalized name, never the raw code",
        arguments: ["en", "es", "de", "it", "ja"])
    func everyCodeHasACapitalizedName(localeIdentifier: String) {
        let locale = Locale(identifier: localeIdentifier)

        for code in CaptionsTranslationLanguage.supportedCodes {
            let name = CaptionsTranslationLanguage.displayName(for: code, locale: locale)

            #expect(name != code, "\(code) has no name in \(localeIdentifier)")
            #expect(name.prefix(1) == name.prefix(1).uppercased(with: locale), "\(name) is not capitalized")
        }
    }

    @Test("Names that ICU returns in lowercase are capitalized")
    func lowercaseNamesAreCapitalized() {
        #expect(
            CaptionsTranslationLanguage.displayName(for: "es-ES", locale: Locale(identifier: "es"))
                == "Español (España)")
        #expect(
            CaptionsTranslationLanguage.displayName(for: "it-IT", locale: Locale(identifier: "it"))
                == "Italiano (Italia)")
    }

    @Test("Languages Amazon Translate cannot target, or the system cannot name, are not offered")
    func excludedLanguagesAreNotOffered() {
        let excluded = ["eu-ES", "gl-ES", "zu-ZA", "en-AB", "en-WL"]

        #expect(Set(CaptionsTranslationLanguage.supportedCodes).isDisjoint(with: excluded))
    }

    @Test("The factory exposes captions availability, hidden by default")
    func factoryCaptionsAvailability() {
        let hidden = SettingsFactory(repository: MockSettingsRepository(), statsDataSource: MockStatsDataSource())
        let shown = SettingsFactory(
            repository: MockSettingsRepository(),
            statsDataSource: MockStatsDataSource(),
            isCaptionsTranslationAvailable: true
        )

        #expect(!hidden.isCaptionsTranslationAvailable)
        #expect(shown.isCaptionsTranslationAvailable)
    }
}
