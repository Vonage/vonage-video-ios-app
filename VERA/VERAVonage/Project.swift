import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonage",
    packages: [
        .package(url: "https://github.com/Vonage/vonage-video-client-sdk-swift", .upToNextMinor(from: "2.32.1"))
    ],
    targets: [
        .target(
            name: "VERAVonage",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonage",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonage/**"],
            scripts: [.swiftLint(targetName: "VERAVonage")],
            dependencies: [
                .project(target: "VERACore", path: "../VERACore"),
                .package(product: "VonageClientSDKVideo"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageTests/**"],
            dependencies: [
                .target(name: "VERAVonage"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageTests"]),
            testAction: .targets(["VERAVonageTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
