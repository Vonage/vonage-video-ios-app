import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERABackgroundEffects",
    packages: [
        .package(url: "https://github.com/Vonage/vonage-client-sdk-video-transformers", .upToNextMinor(from: "2.32.1"))
    ],
    targets: [
        .target(
            name: "VERABackgroundEffects",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERABackgroundEffects",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERABackgroundEffects/**"],
            resources: [
                "VERABackgroundEffects/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERABackgroundEffects")],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .package(product: "VonageClientSDKVideoTransformers"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERABackgroundEffectsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERABackgroundEffectsTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERABackgroundEffectsTests/**"],
            dependencies: [
                .target(name: "VERABackgroundEffects")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERABackgroundEffectsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERABackgroundEffectsTests"]),
            testAction: .targets(["VERABackgroundEffectsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
