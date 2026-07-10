// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VERAMeetingRoomSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "VERAMeetingRoomSDK",
            targets: ["VERAMeetingRoomSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Vonage/vonage-video-client-sdk-swift",
            .upToNextMinor(from: "2.34.1")
        ),
        .package(
            url: "https://github.com/Vonage/vonage-client-sdk-video-transformers",
            .upToNextMinor(from: "2.33.0")
        ),
    ],
    targets: [
        // MARK: - Foundation Layer

        .target(
            name: "VERADomain",
            path: "VERA/VERADomain/VERADomain"
        ),
        .target(
            name: "VERAConfiguration",
            dependencies: ["VERADomain"],
            path: "VERA/VERAConfiguration/VERAConfiguration"
        ),
        .target(
            name: "VERACommonUI",
            dependencies: ["VERADomain"],
            path: "VERA/VERACommonUI/VERACommonUI",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERACore",
            dependencies: [
                "VERADomain",
                "VERACommonUI",
                "VERAConfiguration",
            ],
            path: "VERA/VERACore/VERACore",
            resources: [.process("Resources")],
            swiftSettings: [.enableUpcomingFeature("BareSlashRegexLiterals")]
        ),

        // MARK: - Meeting Room

        .target(
            name: "VERAMeetingRoom",
            dependencies: [
                "VERADomain",
                "VERACommonUI",
            ],
            path: "VERA/VERAMeetingRoom/VERAMeetingRoom",
            resources: [.process("Resources")]
        ),

        // MARK: - Vonage Integration Layer

        .target(
            name: "VERAVonage",
            dependencies: [
                "VERACore",
                .product(name: "VonageClientSDKVideo", package: "vonage-video-client-sdk-swift"),
            ],
            path: "VERA/VERAVonage/VERAVonage"
        ),

        // MARK: - Feature Modules

        .target(
            name: "VERAChat",
            dependencies: [
                "VERACommonUI",
                "VERADomain",
            ],
            path: "VERA/VERAChat/VERAChat",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERAArchiving",
            dependencies: [
                "VERACommonUI",
                "VERADomain",
            ],
            path: "VERA/VERAArchiving/VERAArchiving",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERABackgroundEffects",
            dependencies: [
                "VERAVonage",
                "VERACommonUI",
                .product(
                    name: "VonageClientSDKVideoTransformers",
                    package: "vonage-client-sdk-video-transformers"
                ),
            ],
            path: "VERA/VERABackgroundEffects/VERABackgroundEffects",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERACaptions",
            dependencies: [
                "VERACommonUI",
                "VERADomain",
            ],
            path: "VERA/VERACaptions/VERACaptions",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERAReactions",
            dependencies: ["VERACommonUI"],
            path: "VERA/VERAReactions/VERAReactions",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERASettings",
            dependencies: [
                "VERADomain",
                "VERACommonUI",
            ],
            path: "VERA/VERASettings/VERASettings",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERAScreenShare",
            dependencies: ["VERACommonUI"],
            path: "VERA/VERAScreenShare/VERAScreenShare",
            resources: [.process("Resources")]
        ),
        .target(
            name: "VERAAudioEffects",
            dependencies: [
                "VERACommonUI",
                "VERAVonage",
                .product(
                    name: "VonageClientSDKVideoTransformers",
                    package: "vonage-client-sdk-video-transformers"
                ),
            ],
            path: "VERA/VERAAudioEffects/VERAAudioEffects",
            resources: [.process("Resources")]
        ),

        // MARK: - Vonage Plugin Modules

        .target(
            name: "VERAVonageCallKitPlugin",
            dependencies: [
                "VERAVonage",
                "VERACore",
                "VERACommonUI",
            ],
            path: "VERA/VERAVonageCallKitPlugin/VERAVonageCallKitPlugin"
        ),
        .target(
            name: "VERAVonageChatPlugin",
            dependencies: [
                "VERAChat",
                "VERAVonage",
            ],
            path: "VERA/VERAVonageChatPlugin/VERAVonageChatPlugin"
        ),
        .target(
            name: "VERAVonageArchivingPlugin",
            dependencies: [
                "VERAVonage",
                "VERAArchiving",
            ],
            path: "VERA/VERAVonageArchivingPlugin/VERAVonageArchivingPlugin"
        ),
        .target(
            name: "VERAVonageCaptionsPlugin",
            dependencies: [
                "VERAVonage",
                "VERACaptions",
            ],
            path: "VERA/VERAVonageCaptionsPlugin/VERAVonageCaptionsPlugin"
        ),
        .target(
            name: "VERAVonageReactionsPlugin",
            dependencies: [
                "VERAReactions",
                "VERAVonage",
            ],
            path: "VERA/VERAVonageReactionsPlugin/VERAVonageReactionsPlugin"
        ),
        .target(
            name: "VERAVonageSettingsPlugin",
            dependencies: [
                "VERASettings",
                "VERAVonage",
            ],
            path: "VERA/VERAVonageSettingsPlugin/VERAVonageSettingsPlugin"
        ),
        .target(
            name: "VERAVonageScreenSharePlugin",
            dependencies: [
                "VERAScreenShare",
                "VERAVonage",
            ],
            path: "VERA/VERAVonageScreenSharePlugin/VERAVonageScreenSharePlugin"
        ),

        // MARK: - SDK Aggregator

        .target(
            name: "VERAMeetingRoomSDK",
            dependencies: [
                "VERAMeetingRoom",
                "VERAVonage",
                "VERACore",
                "VERACommonUI",
                "VERADomain",
                "VERAVonageCallKitPlugin",
                "VERAChat",
                "VERAVonageChatPlugin",
                "VERAArchiving",
                "VERAVonageArchivingPlugin",
                "VERABackgroundEffects",
                "VERACaptions",
                "VERAVonageCaptionsPlugin",
                "VERAReactions",
                "VERAVonageReactionsPlugin",
                "VERASettings",
                "VERAVonageSettingsPlugin",
                "VERAScreenShare",
                "VERAVonageScreenSharePlugin",
                "VERAAudioEffects",
                .product(
                    name: "VonageClientSDKVideoTransformers",
                    package: "vonage-client-sdk-video-transformers"
                ),
            ],
            path: "VERA/VERAMeetingRoomSDK/VERAMeetingRoomSDK"
        ),

        // MARK: - Test Support

        .target(
            name: "VERATestHelpers",
            dependencies: ["VERACore"],
            path: "VERA/VERACore/VERATestHelpers"
        ),

        // MARK: - Tests

        .testTarget(
            name: "VERAMeetingRoomSDKTests",
            dependencies: [
                "VERAMeetingRoomSDK",
                "VERATestHelpers",
            ],
            path: "VERA/VERAMeetingRoomSDK/VERAMeetingRoomSDKTests"
        ),
    ]
)
