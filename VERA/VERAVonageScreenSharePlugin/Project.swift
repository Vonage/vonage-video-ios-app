import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageScreenSharePlugin",
    packages: [
        .vonageVideoSDK,
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

        // MARK: - Broadcast Upload Extension

        .target(
            name: "BroadcastExtension",
            destinations: .iOS,
            product: .appExtension,
            bundleId: "com.vonage.VERA.BroadcastExtension",
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
                    "DEVELOPMENT_TEAM": "PR6C39UQ38",
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.vonage.VERA.BroadcastExtension",
                ]) { _, new in new },
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_STYLE": "Automatic",
                            "CODE_SIGN_IDENTITY": "iPhone Developer",
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_STYLE": "Manual",
                            "CODE_SIGN_IDENTITY": "iPhone Distribution",
                            "PROVISIONING_PROFILE_SPECIFIER": "BroadcastExtension_App_Store",
                        ]
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
        )
    ]
)
