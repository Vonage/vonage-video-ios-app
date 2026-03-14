import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAAudioEffects",
    packages: [
        .swiftSnapshotTesting,
        .vonageVideoTransformersSDK,
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAAudioEffects",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAAudioEffects",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAAudioEffects/**"],
            resources: ["VERAAudioEffects/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAAudioEffects")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .vonageVideoTransformersSDK,
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAAudioEffectsTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAAudioEffectsTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAAudioEffectsTests/**"],
            dependencies: [
                .target(name: "VERAAudioEffects"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAAudioEffectsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAAudioEffectsSnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAAudioEffectsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAAudioEffects"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAAudioEffectsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAAudioEffectsTests"]),
            testAction: .targets(["VERAAudioEffectsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAAudioEffectsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAAudioEffectsSnapshotTests"]),
            testAction: .targets(["VERAAudioEffectsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
