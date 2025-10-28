import ProjectDescription

let project = Project(
    name: "VERAApp",
    targets: [
        .target(
            name: "VERA",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERA",
            infoPlist: "VERA/Info.plist",
            sources: ["VERA/App/**"],
            resources: [
                "VERA/App/Resources/**"
            ],
            entitlements: "VERA/VERA.entitlements",
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERAOpenTok", path: "../VERAOpenTok"),
                .project(target: "VERAOpenTokChatPlugin", path: "../VERAOpenTokChatPlugin")
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
        ),
        .target(
            name: "VERATests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERATests",
            sources: ["VERATests/**"],
            dependencies: [
                .target(name: "VERA")
            ]
        ),
        .target(
            name: "VERAUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.vonage.VERAUITests",
            sources: ["VERAUITests/**"],
            dependencies: [
                .target(name: "VERA")
            ]
        )
    ]
)
