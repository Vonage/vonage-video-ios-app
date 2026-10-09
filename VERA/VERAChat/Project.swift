import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAChat",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        .target(
            name: "VERAChat",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAChat",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAChat/**"],
            resources: [
                "VERAChat/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERAChat")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAChatAppTestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAChatAppTestHelpers",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAChatAppTestHelpers/**"],
            scripts: [.swiftLint(targetName: "VERAChatAppTestHelpers")],
            dependencies: [
                .target(name: "VERAChat")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAChatApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERAChatApp",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAChatApp",
                    "CFBundleDisplayName": "VERAChatApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAChatApp/**"],
            scripts: [.swiftLint(targetName: "VERAChatApp")],
            dependencies: [
                .target(name: "VERAChat"),
                .target(name: "VERAChatAppTestHelpers"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAChatTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAChatTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAChatTests/**"],
            dependencies: [
                .target(name: "VERAChat"),
                .target(name: "VERAChatAppTestHelpers"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAChatSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAChatSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAChatSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAChat"),
                .target(name: "VERAChatAppTestHelpers"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAChatTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAChatTests"]),
            testAction: .targets(["VERAChatTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAChatSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAChatSnapshotTests"]),
            testAction: .targets(["VERAChatSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
