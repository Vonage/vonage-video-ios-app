import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAScreenShare",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAScreenShare",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAScreenShare",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAScreenShare/**"],
            resources: ["VERAScreenShare/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAScreenShare")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAScreenShareApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAScreenShareApp",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAScreenShareApp",
                    "CFBundleDisplayName": "VERAScreenShareApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAScreenShareApp/**"],
            scripts: [.swiftLint(targetName: "VERAScreenShareApp")],
            dependencies: [
                .target(name: "VERAScreenShare")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAScreenShareTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAScreenShareTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAScreenShareTests/**"],
            dependencies: [
                .target(name: "VERAScreenShare")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAScreenShareSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAScreenShareSnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAScreenShareSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAScreenShare"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAScreenShareTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAScreenShareTests"]),
            testAction: .targets(["VERAScreenShareTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAScreenShareSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAScreenShareSnapshotTests"]),
            testAction: .targets(["VERAScreenShareSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
