import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACaptions",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        .target(
            name: "VERACaptions",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACaptions",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACaptions/**"],
            resources: [
                "VERACaptions/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERACaptions")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACaptionsApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERACaptionsApp",
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERACaptionsApp",
                    "CFBundleDisplayName": "VERACaptionsApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERACaptionsApp/**"],
            scripts: [.swiftLint(targetName: "VERACaptionsApp")],
            dependencies: [
                .target(name: "VERACaptions")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACaptionsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACaptionsTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACaptionsTests/**"],
            dependencies: [
                .target(name: "VERACaptions")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACaptionsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERACaptionsSnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERACaptionsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERACaptions"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERACaptionsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACaptionsTests"]),
            testAction: .targets(["VERACaptionsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERACaptionsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACaptionsSnapshotTests"]),
            testAction: .targets(["VERACaptionsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
