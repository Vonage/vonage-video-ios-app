import ProjectDescription

let project = Project(
    name: "VERAOpenTok",
    packages: [
        .package(url: "https://github.com/Vonage/vonage-video-client-sdk-swift", .upToNextMinor(from: "2.31.1"))
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
        )
    ]
)
