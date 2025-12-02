import ProjectDescription

let project = Project(
    name: "VERAOpenTok",
    packages: [
        .package(url: "https://github.com/Vonage/vonage-video-client-sdk-swift", .upToNextMinor(from: "2.32.0"))
    ],
    targets: [
        .target(
            name: "VERAOpenTok",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAOpenTok",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTok/**"],
            dependencies: [
                .project(target: "VERACore", path: "../VERACore"),
                .package(product: "VonageClientSDKVideo"),
            ]
        ),
        .target(
            name: "VERAOpenTokTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAOpenTokTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTokTests/**"],
            dependencies: [
                .target(name: "VERAOpenTok"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOpenTokTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOpenTokTests"]),
            testAction: .targets(["VERAOpenTokTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
