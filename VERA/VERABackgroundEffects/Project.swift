import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERABackgroundEffects",
    packages: [
        .vonageVideoTransformersSDK
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
                .vonageVideoTransformersSDK,
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
