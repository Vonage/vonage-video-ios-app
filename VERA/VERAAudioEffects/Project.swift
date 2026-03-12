import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAAudioEffects",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAAudioEffects",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAAudioEffects",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAAudioEffects/**"],
            resources: ["VERAAudioEffects/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAAudioEffects")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAAudioEffectsApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAAudioEffectsApp",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAAudioEffectsApp",
                    "CFBundleDisplayName": "VERAAudioEffectsApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAAudioEffectsApp/**"],
            scripts: [.swiftLint(targetName: "VERAAudioEffectsApp")],
            dependencies: [
                .target(name: "VERAAudioEffects")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAAudioEffectsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAAudioEffectsTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAAudioEffectsTests/**"],
            dependencies: [
                .target(name: "VERAAudioEffects")
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
