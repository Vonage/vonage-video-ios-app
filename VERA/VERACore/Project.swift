import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACore",
    packages: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", .upToNextMinor(from: "1.18.4"))
    ],
    targets: [
        .target(
            name: "VERACore",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACore",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACore/**"],
            resources: [
                "VERACore/Resources/**",
                "VERACore/Resources/**/*.xcassets",
            ],
            scripts: [.swiftLint],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERAConfiguration", path: "../VERAConfiguration"),
            ]
        ),
        .target(
            name: "VERATestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERATestHelpers",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERATestHelpers/**"],
            dependencies: [
                .target(name: "VERACore")
            ]
        ),
        .target(
            name: "VERACoreTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACore.tests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACoreTests/**"],
            dependencies: [
                .target(name: "VERACore"),
                .target(name: "VERATestHelpers"),
            ]
        ),
        .target(
            name: "VERACoreSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERACore.snapshottests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERACoreSnapshotTests/**"],
            dependencies: [
                .target(name: "VERACore"),
                .target(name: "VERATestHelpers"),
                .package(product: "SnapshotTesting"),
            ]
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
