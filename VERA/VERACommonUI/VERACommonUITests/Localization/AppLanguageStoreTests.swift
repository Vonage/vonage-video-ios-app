import Foundation
import Observation
import Testing

@testable import VERACommonUI

@Suite("App language preferences")
struct AppLanguageStoreTests {
    private func defaults() -> UserDefaults {
        UserDefaults(suiteName: "language-tests-\(UUID().uuidString)")!
    }

    @Test("Defaults to System and matches regional preferred languages")
    func systemMatching() {
        let store = AppLanguageStore(userDefaults: defaults())
        #expect(store.selection == .system)
        #expect(store.resolvedLanguageCode(preferredLanguages: ["es-MX"]) == "es-MX")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["en-GB"]) == "en")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["en-US"]) == "en-US")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["de-AT"]) == "de")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["it-IT"]) == "it")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["ja-JP"]) == "ja")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["es-AR"]) == "es")
        #expect(store.resolvedLanguageCode(preferredLanguages: ["fr-FR", "es-ES"]) == "es")
    }

    @Test("Falls back to English for unsupported or empty system preferences")
    func englishFallback() {
        let store = AppLanguageStore(userDefaults: defaults())
        #expect(store.resolvedLanguageCode(preferredLanguages: ["fr-FR", "ko-KR"]) == "en")
        #expect(store.resolvedLanguageCode(preferredLanguages: []) == "en")
    }

    @Test("Manual choice persists across instances and reset returns to System")
    func persistenceAndReset() {
        let userDefaults = defaults()
        let store = AppLanguageStore(userDefaults: userDefaults)
        store.selection = .spanish
        let reloaded = AppLanguageStore(userDefaults: userDefaults)
        #expect(reloaded.selection == .spanish)
        #expect(reloaded.resolvedLanguageCode(preferredLanguages: ["en-US"]) == "es")
        reloaded.reset()
        #expect(AppLanguageStore(userDefaults: userDefaults).selection == .system)
    }

    @Test("Regional manual choices preserve their own region")
    func regionalLocale() {
        let store = AppLanguageStore(userDefaults: defaults())
        store.selection = .spanishMexico
        #expect(store.locale.language.languageCode?.identifier == "es")
        #expect(store.locale.region?.identifier == "MX")
        store.selection = .englishUS
        #expect(store.locale.region?.identifier == "US")
        #expect(AppLanguage.allCases.map(\.rawValue) == ["system", "en", "en-US", "de", "it", "es", "es-MX", "ja"])
    }

    @Test("Country flags match the web language selector")
    func webFlags() {
        #expect(AppLanguage.allCases.map(\.flag) == [nil, "🇬🇧", "🇺🇸", "🇩🇪", "🇮🇹", "🇪🇸", "🇲🇽", "🇯🇵"])
    }

    @Test("Invalid saved choice recovers to System")
    func invalidSavedChoice() {
        let userDefaults = defaults()
        userDefaults.set("not-a-language", forKey: AppLanguageStore.preferenceKey)
        #expect(AppLanguageStore(userDefaults: userDefaults).selection == .system)
    }

    @Test("Translates a module bundle and falls back per key to its English resources")
    func moduleTranslationFallback() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("language-\(UUID()).bundle")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let info = ["CFBundleIdentifier": "test.language.\(UUID().uuidString)", "CFBundleDevelopmentRegion": "en"]
        let infoData = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try infoData.write(to: root.appendingPathComponent("Info.plist"))
        for (language, strings) in [
            "en": "\"greeting\" = \"Hello\";\n\"english.only\" = \"English fallback\";",
            "es": "\"greeting\" = \"Hola\";",
        ] {
            let folder = root.appendingPathComponent("\(language).lproj")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try strings.write(
                to: folder.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
        }
        let bundle = try #require(Bundle(url: root))
        let store = AppLanguageStore(userDefaults: defaults())
        store.selection = .spanish
        #expect(store.localizedString("greeting", bundle: bundle) == "Hola")
        #expect(
            String(localized: "greeting", bundle: store.localizedBundle(in: bundle), locale: store.locale) == "Hola")
        #expect(store.localizedString("english.only", bundle: bundle) == "English fallback")
        #expect(store.localizedString("untranslated.key", bundle: bundle) == "untranslated.key")
        store.selection = .english
        #expect(store.localizedString("greeting", bundle: bundle) == "Hello")
    }

    @Test(
        "Each shipped language resolves compiled module resources",
        arguments: [
            (AppLanguage.english, "Sign in"),
            (.englishUS, "Sign in"),
            (.german, "Anmelden"),
            (.italian, "Accedi"),
            (.spanish, "Iniciar sesión"),
            (.spanishMexico, "Iniciar sesión"),
            (.japanese, "サインイン"),
        ])
    func shippedResources(language: AppLanguage, expected: String) {
        let store = AppLanguageStore(userDefaults: defaults())
        store.selection = language
        let bundle = Bundle(for: AppLanguageStore.self)
        #expect(store.localizedString("auth_sign_in", bundle: bundle) == expected)
        #expect(
            String(localized: "auth_sign_in", bundle: store.localizedBundle(in: bundle), locale: store.locale)
                == expected)
    }

    @Test("Language reads participate in Observation without requiring a view identity reset")
    func observation() {
        let store = AppLanguageStore(userDefaults: defaults())
        let changed = LockedFlag()
        withObservationTracking {
            _ = store.resolvedLanguageCode()
        } onChange: {
            changed.set()
        }
        store.selection = .spanish
        #expect(changed.value)
    }
}

private final class LockedFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue = false
    var value: Bool { lock.withLock { storedValue } }
    func set() { lock.withLock { storedValue = true } }
}
