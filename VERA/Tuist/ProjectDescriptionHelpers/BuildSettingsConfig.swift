import ProjectDescription

// MARK: - Deployment Targets

/// Deployment target for iOS-only modules (Vonage SDK, plugins, snapshot tests).
public let iOSDeploymentTarget = DeploymentTargets.iOS("17.0")

/// Deployment target for multi-platform modules (unit tests run on macOS without simulator).
public let multiplatformDeploymentTarget = DeploymentTargets.multiplatform(iOS: "17.0", macOS: "14.6")

// MARK: - Bundle & Localization

/// The base bundle identifier for the VERA app.
///
/// All targets that derive their bundle ID from the main app (e.g. extensions)
/// should compose their identifier using this constant:
/// ```swift
/// bundleId: "\(veraAppBundleID).BroadcastExtension"
/// ```
public let veraAppBundleID = "com.vonage.VERA"

/// The languages supported by the app, used in `defaultKnownRegions` and `CFBundleLocalizations`.
public let supportedLanguages: [String] = ["en", "en-US", "de", "it", "es", "es-MX", "ja"]

/// The primary development language for the app.
public let developmentLanguage: String = "en"

/// Returns shared `Project.Options` with localization settings applied.
///
/// Use this in every module's `Project.swift` to ensure consistent language configuration:
/// ```swift
/// let project = Project(
///     name: "MyModule",
///     options: defaultProjectOptions(),
///     ...
/// )
/// ```
public func defaultProjectOptions() -> Project.Options {
    .options(
        defaultKnownRegions: supportedLanguages,
        developmentRegion: developmentLanguage
    )
}

public func baseBuildSettings() -> [String: SettingValue] {
    let languageMode = Environment.swiftLanguageMode.getString(default: "6.0")
    precondition(["5.0", "6.0"].contains(languageMode), "TUIST_SWIFT_LANGUAGE_MODE must be 5.0 or 6.0")
    return [
        "SWIFT_VERSION": .string(languageMode),
        "SWIFT_STRICT_CONCURRENCY": "complete",
        "COMPILATION_CACHE_ENABLE_CACHING": "YES",
        "SWIFT_ENABLE_COMPILE_CACHE": "YES",
        "CLANG_ENABLE_COMPILE_CACHE": "YES",
        "SWIFT_ENABLE_EXPLICIT_MODULES": "YES",
        "SWIFT_USE_INTEGRATED_DRIVER": "YES",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
    ]
}

public func createBaseBuildSettings() -> Settings {
    .settings(base: baseBuildSettings())
}
