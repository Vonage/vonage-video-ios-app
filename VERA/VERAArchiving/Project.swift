import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAArchiving",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        .target(
            name: "VERAArchiving",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAArchiving",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAArchiving/**"],
            resources: [
                "VERAArchiving/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERAArchiving")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAArchivingTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAArchivingTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAArchivingTests/**"],
            dependencies: [
                .target(name: "VERAArchiving"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
                .project(target: "VERAArchivingTestHelpers", path: "../VERAArchiving"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAArchivingTestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAArchivingTestHelpers",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAArchivingTestHelpers/**"],
            dependencies: [
                .target(name: "VERAArchiving")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAArchivingSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAArchivingSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAArchivingSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAArchiving"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAArchivingTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAArchivingTests"]),
            testAction: .targets(["VERAArchivingTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAArchivingSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAArchivingSnapshotTests"]),
            testAction: .targets(["VERAArchivingSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
