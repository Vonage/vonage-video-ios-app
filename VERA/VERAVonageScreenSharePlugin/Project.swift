import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageScreenSharePlugin",
    options: defaultProjectOptions(),
    packages: [
        .vonageVideoSDK
    ],
    targets: [
        .target(
            name: "VERAVonageScreenSharePlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageScreenSharePlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageScreenSharePlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageScreenSharePlugin")],
            dependencies: [
                .project(target: "VERAScreenShare", path: "../VERAScreenShare"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageScreenSharePluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageScreenSharePluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageScreenSharePluginTests/**"],
            dependencies: [
                .project(target: "VERAScreenShare", path: "../VERAScreenShare"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageScreenSharePlugin"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Broadcast Extension Tests
        .target(
            name: "BroadcastExtensionTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.BroadcastExtensionTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: [
                "BroadcastExtensionTests/**",
                "../VERAApp/BroadcastExtension/UserDefaultsScreenShareCredentialsStore.swift",
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Broadcast Upload Extension

        .target(
            name: "BroadcastExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "\(veraAppBundleID).BroadcastExtension",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "VERA Broadcast",
                "NSExtension": .dictionary([
                    "NSExtensionPointIdentifier": "com.apple.broadcast-services-upload",
                    "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).SampleHandler",
                    "RPBroadcastProcessMode": "RPBroadcastProcessModeSampleBuffer",
                ]),
            ]),
            sources: ["../VERAApp/BroadcastExtension/**/*.swift"],
            entitlements: "../VERAApp/BroadcastExtension/BroadcastExtension.entitlements",
            dependencies: [
                .vonageVideoSDK,
                .sdk(name: "VideoToolbox", type: .framework, status: .required),
                .sdk(name: "CoreMedia", type: .framework, status: .required),
                .sdk(name: "CoreVideo", type: .framework, status: .required),
                .sdk(name: "ReplayKit", type: .framework, status: .required),
            ],
            settings: .settings(
                base: baseBuildSettings().merging([
                    "PRODUCT_BUNDLE_IDENTIFIER": "\(veraAppBundleID).BroadcastExtension"
                ]) { _, new in new },
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_STYLE": "Automatic",
                            "CODE_SIGN_IDENTITY": "iPhone Developer",
                        ],
                        xcconfig: "../Config/Signing.xcconfig"
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_STYLE": "Manual",
                            "CODE_SIGN_IDENTITY": "iPhone Distribution",
                            "PROVISIONING_PROFILE_SPECIFIER": "BroadcastExtension_App_Store",
                        ],
                        xcconfig: "../Config/Signing.xcconfig"
                    ),
                ]
            )
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageScreenSharePluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageScreenSharePluginTests"]),
            testAction: .targets(["VERAVonageScreenSharePluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "BroadcastExtensionTests",
            shared: true,
            buildAction: .buildAction(targets: ["BroadcastExtensionTests"]),
            testAction: .targets(["BroadcastExtensionTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
