import ProjectDescription

let project = Project(
    name: "VERA",
    targets: [
        .target(
            name: "VERA",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERA",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "NSCameraUsageDescription": "VERA needs camera access to enable video calls",
                "NSMicrophoneUsageDescription": "VERA needs microphone access to enable audio during video calls"
            ]),
            sources: ["VERAApp/VERA/App/**"],
            resources: ["VERAApp/VERA/Resources/**"],
            entitlements: "VERAApp/VERA/VERA.entitlements",
            dependencies: [
                .project(target: "VERACore", path: "VERACore"),
                .project(target: "VERAChat", path: "VERAChat"),
                .project(target: "VERAOpenTok", path: "VERAOpenTok"),
                .project(target: "VERAOpenTokChatPlugin", path: "VERAOpenTokChatPlugin"),
                .project(target: "VERACommonUI", path: "VERACommonUI")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "PR6C39UQ38",
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.vonage.VERA"
                ],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "CODE_SIGN_STYLE": "Automatic",
                            "CODE_SIGN_IDENTITY": "iPhone Developer"
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "CODE_SIGN_STYLE": "Manual",
                            "CODE_SIGN_IDENTITY": "iPhone Distribution",
                            "PROVISIONING_PROFILE_SPECIFIER": "App_Store_VERA"
                        ]
                    )
                ]
            )
        )
    ]
)
