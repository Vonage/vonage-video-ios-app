import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAOKTA",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAOKTA",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAOKTA",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAOKTA/**"],
            resources: ["VERAOKTA/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAOKTA")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAOKTAApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAOKTAApp",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAOKTAApp",
                    "CFBundleDisplayName": "VERAOKTAApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAOKTAApp/**"],
            scripts: [.swiftLint(targetName: "VERAOKTAApp")],
            dependencies: [
                .target(name: "VERAOKTA")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAOKTATests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAOKTATests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAOKTATests/**"],
            dependencies: [
                .target(name: "VERAOKTA")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAOKTASnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAOKTASnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOKTASnapshotTests/**"],
            dependencies: [
                .target(name: "VERAOKTA"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOKTATests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOKTATests"]),
            testAction: .targets(["VERAOKTATests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAOKTASnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOKTASnapshotTests"]),
            testAction: .targets(["VERAOKTASnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
