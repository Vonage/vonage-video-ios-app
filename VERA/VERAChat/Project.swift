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
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ]
        ),
        .target(
            name: "VERAChatAppTestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAChatAppTestHelpers",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAChatAppTestHelpers/**"],
            dependencies: [
                .project(target: "VERAChat", path: ".")
            ]
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
                ].merging(combinedPlistValues(), uniquingKeysWith: { _, new in new })),
            sources: ["VERAChatApp/**"],
            dependencies: [
                .project(target: "VERAChat", path: "."),
                .project(target: "VERAChatAppTestHelpers", path: "."),
            ]
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
            ]
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
            ]
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
