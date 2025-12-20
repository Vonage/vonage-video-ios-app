import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAChat",
    packages: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", .upToNextMinor(from: "1.18.4"))
    ],
    targets: [
        .target(
            name: "VERAChat",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAChat",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAChat/**"],
            resources: [
                "VERAChat/Resources/**"
            ],
            scripts: [.swiftLint],
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
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAChatAppTestHelpers/**"],
            scripts: [.swiftLint],
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
            scripts: [.swiftLint],
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
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
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
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAChatSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAChat"),
                .target(name: "VERAChatAppTestHelpers"),
                .package(product: "SnapshotTesting"),
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
