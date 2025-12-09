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

// MARK: - Dynamic Dependencies

/// Builds target dependencies dynamically based on the chat feature flag.
///
/// Always includes core modules (Core, OpenTok, CommonUI, Configuration, CallKit plugin).
/// When chat is enabled, also includes `VERAChat` and `VERAOpenTokChatPlugin`.
///
/// - Returns: The list of `TargetDependency` for the main app target.
private func createDependencies() -> [TargetDependency] {
    var dependencies: [TargetDependency] = [
        .project(target: "VERACore", path: "VERACore"),
        .project(target: "VERAOpenTok", path: "VERAOpenTok"),
        .project(target: "VERACommonUI", path: "VERACommonUI"),
        .project(target: "VERAConfiguration", path: "VERAConfiguration"),
        .project(target: "VERAOpenTokCallKitPlugin", path: "VERAOpenTokCallKitPlugin"),
    ]

    if isChatEnabled() {
        dependencies.append(contentsOf: [
            .project(target: "VERAChat", path: "VERAChat"),
            .project(target: "VERAOpenTokChatPlugin", path: "VERAOpenTokChatPlugin"),
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
    var baseSettings: [String: SettingValue] = [:]

    if isChatEnabled() {
        baseSettings["CHAT_ENABLED"] = "1"
        baseSettings["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = "$(inherited) CHAT_ENABLED"
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
