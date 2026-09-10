import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACore",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        .target(
            name: "VERACore",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACore",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERACore/**"],
            resources: [
                "VERACore/Resources/**",
                "VERACore/Resources/**/*.xcassets",
            ],
            scripts: [.swiftLint(targetName: "VERACore")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERAConfiguration", path: "../VERAConfiguration"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERATestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERATestHelpers",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERATestHelpers/**"],
            dependencies: [
                .target(name: "VERACore")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACoreTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACore.tests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERACoreTests/**"],
            dependencies: [
                .target(name: "VERACore"),
                .target(name: "VERATestHelpers"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACoreSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERACore.snapshottests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERACoreSnapshotTests/**"],
            dependencies: [
                .target(name: "VERACore"),
                .target(name: "VERATestHelpers"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERACoreTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACoreTests"]),
            testAction: .targets(["VERACoreTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERACoreSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACoreSnapshotTests"]),
            testAction: .targets(["VERACoreSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
