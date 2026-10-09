import Foundation
import Observation

/// Languages for which the app ships localization resources.
public enum AppLanguage: String, CaseIterable, Codable, Sendable, Identifiable {
    case system
    case english = "en"
    case englishUS = "en-US"
    case german = "de"
    case italian = "it"
    case spanish = "es"
    case spanishMexico = "es-MX"
    case japanese = "ja"

    /// Autonyms and order match the web application's language selector.
    public var displayName: String {
        switch self {
        case .system: return "System Default"
        case .english: return "English"
        case .englishUS: return "English (US)"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .spanish: return "Español"
        case .spanishMexico: return "Español (México)"
        case .japanese: return "日本語"
        }
    }

    /// Country flags match the web app's landing-page language selector.
    public var flag: String? {
        switch self {
        case .system: return nil
        case .english: return "🇬🇧"
        case .englishUS: return "🇺🇸"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .spanish: return "🇪🇸"
        case .spanishMexico: return "🇲🇽"
        case .japanese: return "🇯🇵"
        }
    }

    public var id: String { rawValue }
}

/// Shares an observable, persisted language choice across the feature modules.
/// Reads can occur during background string formatting; the selection is protected by a lock.
@Observable
public final class AppLanguageStore: @unchecked Sendable {
    public static let shared = AppLanguageStore()
    public static let preferenceKey = "com.vonage.vera.appLanguage"

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let lock = NSLock()
    @ObservationIgnored private var storedSelection: AppLanguage

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        storedSelection =
            userDefaults.string(forKey: Self.preferenceKey).flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    public var selection: AppLanguage {
        get {
            access(keyPath: \.selection)
            return lock.withLock { storedSelection }
        }
        set {
            withMutation(keyPath: \.selection) {
                lock.withLock {
                    storedSelection = newValue
                    userDefaults.set(newValue.rawValue, forKey: Self.preferenceKey)
                }
            }
        }
    }

    /// Matches regional language preferences to bundled languages, falling back to English.
    public func resolvedLanguageCode(preferredLanguages: [String] = Locale.preferredLanguages) -> String {
        let selected = selection
        guard selected == .system else { return selected.rawValue }
        let supported = Set(AppLanguage.allCases.filter { $0 != .system }.map(\.rawValue))
        for preferred in preferredLanguages {
            let locale = Locale(identifier: preferred)
            guard let language = locale.language.languageCode?.identifier else { continue }
            if let region = locale.region?.identifier {
                let regional = "\(language)-\(region)"
                if supported.contains(regional) { return regional }
            }
            if supported.contains(language) { return language }
        }
        return "en"
    }

    public var locale: Locale {
        let code = resolvedLanguageCode()
        if Locale(identifier: code).region != nil { return Locale(identifier: code) }
        let region = Locale.current.region.map { "_" + $0.identifier } ?? ""
        return Locale(identifier: code + region)
    }

    public func reset() {
        selection = .system
    }

    /// Explicitly selects the module's language resources and falls back per key to English.
    public func localizedString(_ key: String, bundle: Bundle = .main, table: String? = nil) -> String {
        let language = resolvedLanguageCode()
        if let localizedBundle = languageBundle(language, in: bundle) {
            let value = localizedBundle.localizedString(forKey: key, value: key, table: table)
            if value != key { return value }
        }
        if let englishBundle = languageBundle("en", in: bundle) {
            return englishBundle.localizedString(forKey: key, value: key, table: table)
        }
        return key
    }

    /// Foundation's String(localized:) needs an explicitly selected resource bundle;
    /// its locale argument only controls formatting, not resource selection.
    public func localizedBundle(in bundle: Bundle) -> Bundle {
        languageBundle(resolvedLanguageCode(), in: bundle)
            ?? languageBundle("en", in: bundle)
            ?? bundle
    }

    private func languageBundle(_ language: String, in bundle: Bundle) -> Bundle? {
        guard let url = bundle.url(forResource: language, withExtension: "lproj") else { return nil }
        return Bundle(url: url)
    }
}
