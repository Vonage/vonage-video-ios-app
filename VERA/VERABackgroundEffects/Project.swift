import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERABackgroundEffects",
    options: defaultProjectOptions(),
    packages: [
        .vonageVideoTransformersSDK
    ],
    targets: [
        .target(
            name: "VERABackgroundEffects",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERABackgroundEffects",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERABackgroundEffects/**"],
            resources: [
                "VERABackgroundEffects/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERABackgroundEffects")],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ] + TargetDependency.vonageVideoTransformersSDKDependencies,
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERABackgroundEffectsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERABackgroundEffectsTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERABackgroundEffectsTests/**"],
            dependencies: [
                .target(name: "VERABackgroundEffects"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERABackgroundEffectsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERABackgroundEffectsSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERABackgroundEffectsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERABackgroundEffects"),
                .swiftSnapshotTesting,
                .project(target: "VERATestHelpers", path: "../VERACore"),
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
        ),
        .scheme(
            name: "VERABackgroundEffectsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERABackgroundEffectsSnapshotTests"]),
            testAction: .targets(["VERABackgroundEffectsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
