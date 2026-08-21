import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAReactions",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAReactions",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAReactions",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAReactions/**"],
            resources: ["VERAReactions/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAReactions")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAReactionsApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAReactionsApp",
            deploymentTargets: multiplatformDeploymentTarget,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAReactionsApp",
                    "CFBundleDisplayName": "VERAReactionsApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAReactionsApp/**"],
            scripts: [.swiftLint(targetName: "VERAReactionsApp")],
            dependencies: [
                .target(name: "VERAReactions")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAReactionsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAReactionsTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAReactionsTests/**"],
            dependencies: [
                .target(name: "VERAReactions")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAReactionsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAReactionsSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAReactionsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAReactions"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAReactionsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAReactionsTests"]),
            testAction: .targets(["VERAReactionsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAReactionsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAReactionsSnapshotTests"]),
            testAction: .targets(["VERAReactionsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
