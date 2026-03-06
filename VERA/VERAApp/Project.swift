import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAApp",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERA",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERA",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERA",
                    "CFBundleDisplayName": "VERA",
                    "LSApplicationCategoryType": "public.app-category.video",
                    "NSCameraUsageDescription":
                        "VERA needs access to your camera to share your video during video calls and meetings.",
                    "NSMicrophoneUsageDescription":
                        "VERA needs access to your microphone to share your audio during video calls and meetings.",
                ].merging(orientationPlistValues()) { _, new in new }),
            sources: ["VERA/App/**"],
            resources: [
                "VERA/App/Resources/**"
            ],
            entitlements: "VERA/VERA.entitlements",
            scripts: [.swiftLint(targetName: "VERA")],
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERAReactions", path: "../VERAReactions"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERAVonageChatPlugin", path: "../VERAVonageChatPlugin"),
                .project(target: "VERAVonageReactionsPlugin", path: "../VERAVonageReactionsPlugin"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "PR6C39UQ38",
                    "PRODUCT_BUNDLE_IDENTIFIER": "com.vonage.VERA",
                ],
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
                            "PROVISIONING_PROFILE_SPECIFIER": "App_Store_VERA",
                        ]
                    ),
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
        ),
    ]
)
