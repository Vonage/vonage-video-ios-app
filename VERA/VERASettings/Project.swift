import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERASettings",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERASettings",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERASettings",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERASettings/**"],
            resources: ["VERASettings/Resources/**"],
            scripts: [.swiftLint(targetName: "VERASettings")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERASettingsApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERASettingsApp",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERASettingsApp",
                    "CFBundleDisplayName": "VERASettingsApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERASettingsApp/**"],
            scripts: [.swiftLint(targetName: "VERASettingsApp")],
            dependencies: [
                .target(name: "VERASettings")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERASettingsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERASettingsTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERASettingsTests/**"],
            dependencies: [
                .target(name: "VERASettings")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERASettingsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERASettingsSnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERASettingsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERASettings"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERASettingsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERASettingsTests"]),
            testAction: .targets(["VERASettingsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERASettingsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERASettingsSnapshotTests"]),
            testAction: .targets(["VERASettingsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
