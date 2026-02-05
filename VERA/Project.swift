import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

// MARK: - Configuration Reading

/// Reads the app configuration from `Config/app-config.json`.
///
/// - Returns: A dictionary with the parsed JSON configuration.
/// - Important: Crashes with `fatalError` if the file cannot be read or parsed.
/// - SeeAlso: ``isChatEnabled()``
private func readAppConfig() -> [String: Any] {
    let configPath = "./Config/app-config.json"
    guard let configData = FileManager.default.contents(atPath: configPath) else {
        fatalError("Could not read app-config.json")
    }

    do {
        let json = try JSONSerialization.jsonObject(with: configData) as! [String: Any]
        return json
    } catch {
        fatalError("Failed to parse app-config.json: \(error)")
    }
}

/// Returns whether chat is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowChat": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowChat` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func isChatEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowChat"] as! Bool
}

/// Returns whether archiving is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowArchiving": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowArchiving` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func isArchivingEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowArchiving"] as! Bool
}

/// Returns whether background effects are enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "videoSettings": {
///     "allowBackgroundEffects": true
///   }
/// }
/// ```
/// - Returns: `true` if `videoSettings.allowBackgroundEffects` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func areBackgroundEffectsEnabled() -> Bool {
    let config = readAppConfig()
    let videoSettings = config["videoSettings"] as! [String: Any]
    return videoSettings["allowBackgroundEffects"] as! Bool
}

/// Returns whether captions is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowCaptions": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowCaptions` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func areCaptionsEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowCaptions"] as! Bool
}

// MARK: - Dynamic Dependencies

/// Builds Swift Package dependencies dynamically based on feature flags.
///
/// - Returns: The list of Swift Package dependencies for the project.
private func createPackages() -> [Package] {
    var packages: [Package] = []

    if areBackgroundEffectsEnabled() {
        packages.append(.vonageVideoTransformersSDK)
    }

    return packages
}

/// Builds target dependencies dynamically based on the chat feature flag.
///
/// Always includes core modules (Core, Vonage, CommonUI, Configuration, CallKit plugin).
/// When chat is enabled, also includes `VERAChat` and `VERAVonageChatPlugin`.
///
/// - Returns: The list of `TargetDependency` for the main app target.
private func createDependencies() -> [TargetDependency] {
    var dependencies: [TargetDependency] = [
        .project(target: "VERACore", path: "VERACore"),
        .project(target: "VERAVonage", path: "VERAVonage"),
        .project(target: "VERACommonUI", path: "VERACommonUI"),
        .project(target: "VERAConfiguration", path: "VERAConfiguration"),
        .project(target: "VERAVonageCallKitPlugin", path: "VERAVonageCallKitPlugin"),
    ]

    if isChatEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAChat", path: "VERAChat"),
            .project(target: "VERAVonageChatPlugin", path: "VERAVonageChatPlugin"),
        ])
    }

    if isArchivingEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAArchiving", path: "VERAArchiving"),
            .project(target: "VERAVonageArchivingPlugin", path: "VERAVonageArchivingPlugin"),
        ])
    }

    if areBackgroundEffectsEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERABackgroundEffects", path: "VERABackgroundEffects"),
            .vonageVideoTransformersSDK,
        ])
    }

    if areCaptionsEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERACaptions", path: "VERACaptions")
        ])
    }
    return dependencies
}

// MARK: - Dynamic Build Settings

/// Creates build settings based on the chat feature flag.
///
/// When chat is enabled:
/// - Sets `CHAT_ENABLED=1`
/// - Appends `CHAT_ENABLED` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
///
/// This allows conditional compilation in Swift:
/// ```swift
/// #if CHAT_ENABLED
/// // Chat-related code
/// #endif
/// ```
///
/// - Returns: A `Settings` object containing base and configuration-specific settings.
private func createBuildSettings() -> Settings {
    var baseSettings: [String: SettingValue] = baseBuildSettings()

    var flags: [String] = []

    if isChatEnabled() {
        baseSettings["CHAT_ENABLED"] = "1"
        flags.append("CHAT_ENABLED")
        print("Chat feature enabled in build settings.")
    }

    if isArchivingEnabled() {
        baseSettings["ARCHIVING_ENABLED"] = "1"
        flags.append("ARCHIVING_ENABLED")
        print("Archiving feature enabled in build settings.")
    }

    if areBackgroundEffectsEnabled() {
        baseSettings["BACKGROUND_EFFECTS_ENABLED"] = "1"
        flags.append("BACKGROUND_EFFECTS_ENABLED")
        print("Background effects feature enabled in build settings.")
    }

    if areCaptionsEnabled() {
        baseSettings["CAPTIONS_ENABLED"] = "1"
        flags.append("CAPTIONS_ENABLED")
        print("Captions feature enabled in build settings.")
    }

    if !flags.isEmpty {
        baseSettings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) \(flags.joined(separator: " "))"
    }

    return .settings(
        base: baseSettings,
        configurations: [
            .debug(
                name: "Debug",
                settings: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "iPhone Developer",
                ],
                xcconfig: "Config/Signing.xcconfig"
            ),
            .release(
                name: "Release",
                settings: [
                    "CODE_SIGN_STYLE": "Manual",
                    "CODE_SIGN_IDENTITY": "iPhone Distribution",
                    "PROVISIONING_PROFILE_SPECIFIER": "App_Store_VERA",
                ],
                xcconfig: "Config/Signing.xcconfig"
            ),
        ]
    )
}

/// The Tuist project definition for the VERA app and tests.
///
/// - Includes the main `VERA` iOS app target with dynamic dependencies and build settings.
/// - Adds `VERATests` as unit tests targeting the app.
/// - Merges additional Info.plist values via `combinedPlistValues()` from helpers.
///
/// - SeeAlso: ``createDependencies()``, ``createBuildSettings()``, `combinedPlistValues()`
let project = Project(
    name: "VERA",
    options: .options(
        defaultKnownRegions: ["en", "es"],
        developmentRegion: "en"
    ),
    packages: createPackages(),
    targets: [
        .target(
            name: "VERA",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERA",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERA",
                    "CFBundleDisplayName": "VERA",
                    "CFBundleDevelopmentRegion": "en",
                    "CFBundleLocalizations": .array(["en", "es"]),
                    "LSApplicationCategoryType": "public.app-category.video",
                    "NSCameraUsageDescription":
                        "VERA needs access to your camera to share your video during video calls and meetings.",
                    "NSMicrophoneUsageDescription":
                        "VERA needs access to your microphone to share your audio during video calls and meetings.",
                    "UIBackgroundModes": .array(["audio", "voip"]),
                    "CFBundleShortVersionString": "$(MARKETING_VERSION)",
                    "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
                    "ITSAppUsesNonExemptEncryption": false,
                    "NSCameraReactionEffectGesturesEnabledDefault": false,
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAApp/VERA/App/**"],
            resources: ["VERAApp/VERA/Resources/**"],
            entitlements: "VERAApp/VERA/VERA.entitlements",
            dependencies: createDependencies(),
            settings: createBuildSettings()
        ),
        .target(
            name: "VERATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERATests",
            sources: ["VERAApp/VERATests/**"],
            dependencies: [
                .target(name: "VERA")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "VERATests",
            shared: true,
            buildAction: .buildAction(targets: ["VERATests"]),
            testAction: .targets(["VERATests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
