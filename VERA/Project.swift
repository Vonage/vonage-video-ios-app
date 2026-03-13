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

/// Returns whether emojis/reactions are enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowEmojis": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowEmojis` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func areEmojisEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowEmojis"] as! Bool
}

/// Returns whether Settings is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowSettings": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowSettings` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func areSettingsEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowSettings"] as! Bool
}

/// Returns whether screen share is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowScreenShare": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowScreenShare` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func isScreenShareEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowScreenShare"] as! Bool
}

/// Returns whether AudioEffects is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "meetingRoomSettings": {
///     "allowAudioEffects": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `meetingRoomSettings.allowAudioEffects` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func areAudioEffectsEnabled() -> Bool {
    let config = readAppConfig()
    let meetingRoomSettings = config["meetingRoomSettings"] as! [String: Any]
    return meetingRoomSettings["allowAudioEffects"] as! Bool
}

/// Returns whether Settings is enabled according to `app-config.json`.
///
/// Expects the JSON shape:
/// ```json
/// {
///   "audioSettings": {
///     "allowAdvancedNoiseSuppression": true
///   }
/// }
/// ```
///
/// - Returns: `true` if `audioSettings.allowAdvancedNoiseSuppression` is `true`, else `false`.
/// - Important: Uses force-casts based on the expected config shape; misconfigured JSON will crash.
private func isAdvancedNoiseSuppressionEnabled() -> Bool {
    let config = readAppConfig()
    let audioSettings = config["audioSettings"] as! [String: Any]
    return audioSettings["allowAdvancedNoiseSuppression"] as! Bool
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
            .project(target: "VERACaptions", path: "VERACaptions"),
            .project(target: "VERAVonageCaptionsPlugin", path: "VERAVonageCaptionsPlugin"),
        ])
    }

    if areEmojisEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAReactions", path: "VERAReactions"),
            .project(target: "VERAVonageReactionsPlugin", path: "VERAVonageReactionsPlugin"),
        ])
    }
    if areSettingsEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERASettings", path: "VERASettings"),
            .project(target: "VERAVonageSettingsPlugin", path: "VERAVonageSettingsPlugin"),
        ])
    }

    if isScreenShareEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAScreenShare", path: "VERAScreenShare"),
            .project(target: "VERAVonageScreenSharePlugin", path: "VERAVonageScreenSharePlugin"),
            .project(target: "BroadcastExtension", path: "VERAVonageScreenSharePlugin"),
        ])
    }

    if areAudioEffectsEnabled() && isAdvancedNoiseSuppressionEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAAudioEffects", path: "VERAAudioEffects")
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

    if areEmojisEnabled() {
        baseSettings["REACTIONS_ENABLED"] = "1"
        flags.append("REACTIONS_ENABLED")
        print("Reactions feature enabled in build settings.")
    }

    if areSettingsEnabled() {
        baseSettings["SETTINGS_ENABLED"] = "1"
        flags.append("SETTINGS_ENABLED")
        print("Settings feature enabled in build settings.")
    }

    if isScreenShareEnabled() {
        baseSettings["SCREEN_SHARE_ENABLED"] = "1"
        flags.append("SCREEN_SHARE_ENABLED")
        print("Screen share feature enabled in build settings.")
    }

    if areAudioEffectsEnabled() && isAdvancedNoiseSuppressionEnabled() {
        baseSettings["AUDIOEFFECTS_ENABLED"] = "1"
        flags.append("AUDIOEFFECTS_ENABLED")
        print("AudioEffects feature enabled in build settings.")
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
    options: defaultProjectOptions(),
    packages: createPackages(),
    targets: [
        .target(
            name: "VERA",
            destinations: .iOS,
            product: .app,
            bundleId: veraAppBundleID,
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERA",
                    "CFBundleDisplayName": "VERA",
                    "CFBundleDevelopmentRegion": .string(developmentLanguage),
                    "CFBundleLocalizations": .array(supportedLanguages.map { .string($0) }),
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
            bundleId: "\(veraAppBundleID)Tests",
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
