import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAOnTheGo",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAOnTheGo",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAOnTheGo",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAOnTheGo/**"],
            resources: ["VERAOnTheGo/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAOnTheGo")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAOnTheGoApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAOnTheGoApp",
            deploymentTargets: multiplatformDeploymentTarget,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAOnTheGoApp",
                    "CFBundleDisplayName": "VERAOnTheGoApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAOnTheGoApp/**"],
            scripts: [.swiftLint(targetName: "VERAOnTheGoApp")],
            dependencies: [
                .target(name: "VERAOnTheGo")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAOnTheGoTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAOnTheGoTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAOnTheGoTests/**"],
            dependencies: [
                .target(name: "VERAOnTheGo")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAOnTheGoSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAOnTheGoSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAOnTheGoSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAOnTheGo"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOnTheGoTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOnTheGoTests"]),
            testAction: .targets(["VERAOnTheGoTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAOnTheGoSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOnTheGoSnapshotTests"]),
            testAction: .targets(["VERAOnTheGoSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
