import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAMeetingRoomSDK",
    options: defaultProjectOptions(),
    packages: [
        .vonageVideoTransformersSDK
    ],
    targets: [
        .target(
            name: "VERAMeetingRoomSDK",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAMeetingRoomSDK",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAMeetingRoomSDK/**"],
            resources: [
                "VERAMeetingRoomSDK/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERAMeetingRoomSDK")],
            dependencies: [
                // Core modules
                .project(target: "VERAMeetingRoom", path: "../VERAMeetingRoom"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERAFeedback", path: "../VERAFeedback"),
                // Always-included plugins
                .project(target: "VERAVonageCallKitPlugin", path: "../VERAVonageCallKitPlugin"),
                // Feature modules
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAVonageChatPlugin", path: "../VERAVonageChatPlugin"),
                .project(target: "VERAArchiving", path: "../VERAArchiving"),
                .project(target: "VERAVonageArchivingPlugin", path: "../VERAVonageArchivingPlugin"),
                .project(target: "VERABackgroundEffects", path: "../VERABackgroundEffects"),
                .project(target: "VERACaptions", path: "../VERACaptions"),
                .project(target: "VERAVonageCaptionsPlugin", path: "../VERAVonageCaptionsPlugin"),
                .project(target: "VERAReactions", path: "../VERAReactions"),
                .project(target: "VERAVonageReactionsPlugin", path: "../VERAVonageReactionsPlugin"),
                .project(target: "VERASettings", path: "../VERASettings"),
                .project(target: "VERAVonageSettingsPlugin", path: "../VERAVonageSettingsPlugin"),
                .project(target: "VERAScreenShare", path: "../VERAScreenShare"),
                .project(target: "VERAVonageScreenSharePlugin", path: "../VERAVonageScreenSharePlugin"),
                .project(target: "VERAAudioEffects", path: "../VERAAudioEffects"),
                .project(target: "VERAFeedback", path: "../VERAFeedback"),
                .vonageVideoTransformersSDK,
            ],
            settings: createBaseBuildSettings()
        ),
        // MARK: - Demo App Target

        .target(
            name: "VERAMeetingRoomSDKApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERAMeetingRoomSDKApp",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAMeetingRoomSDKApp",
                    "CFBundleDisplayName": "MeetingRoom SDK",
                    "NSCameraUsageDescription":
                        "VERAMeetingRoomSDKApp needs access to your camera to share your video during video calls.",
                    "NSMicrophoneUsageDescription":
                        "VERAMeetingRoomSDKApp needs access to your microphone to share your audio during video calls.",
                    "UIBackgroundModes": .array(["audio", "voip"]),
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAMeetingRoomSDKApp/**"],
            scripts: [.swiftLint(targetName: "VERAMeetingRoomSDKApp")],
            dependencies: [
                .target(name: "VERAMeetingRoomSDK"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .vonageVideoTransformersSDK,
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target

        .target(
            name: "VERAMeetingRoomSDKTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAMeetingRoomSDKTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAMeetingRoomSDKTests/**"],
            dependencies: [
                .target(name: "VERAMeetingRoomSDK"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAMeetingRoomSDKApp",
            shared: true,
            buildAction: .buildAction(targets: ["VERAMeetingRoomSDKApp"]),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAMeetingRoomSDKTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAMeetingRoomSDKTests"]),
            testAction: .targets(["VERAMeetingRoomSDKTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
