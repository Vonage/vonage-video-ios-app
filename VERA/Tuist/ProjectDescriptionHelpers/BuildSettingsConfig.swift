import ProjectDescription

/// The base bundle identifier for the VERA app.
///
/// All targets that derive their bundle ID from the main app (e.g. extensions)
/// should compose their identifier using this constant:
/// ```swift
/// bundleId: "\(veraAppBundleID).BroadcastExtension"
/// ```
public let veraAppBundleID = "com.vonage.VERA"

public func baseBuildSettings() -> [String: SettingValue] {
    [
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
