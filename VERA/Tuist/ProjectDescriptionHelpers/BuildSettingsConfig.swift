import ProjectDescription

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
