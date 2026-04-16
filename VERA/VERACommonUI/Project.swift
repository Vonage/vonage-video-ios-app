import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACommonUI",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        .target(
            name: "VERACommonUI",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACommonUI",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACommonUI/**"],
            resources: [
                "VERACommonUI/Resources/**",
                "VERACommonUI/Resources/**/*.xcassets",
            ],
            scripts: [.swiftLint(targetName: "VERACommonUI")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACommonUITests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACommonUITests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACommonUITests/**"],
            dependencies: [
                .target(name: "VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACommonUISnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERACommonUISnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERACommonUISnapshotTests/**"],
            dependencies: [
                .target(name: "VERACommonUI"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERACommonUITests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACommonUITests"]),
            testAction: .targets(["VERACommonUITests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERACommonUISnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACommonUISnapshotTests"]),
            testAction: .targets(["VERACommonUISnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
