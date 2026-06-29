import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAFeedback",
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAFeedback",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAFeedback",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAFeedback/**"],
            resources: ["VERAFeedback/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAFeedback")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Demo App Target
        .target(
            name: "VERAFeedbackApp",
            destinations: [.iPhone, .iPad, .mac],
            product: .app,
            bundleId: "com.vonage.VERAFeedbackApp",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleName": "VERAFeedbackApp",
                    "CFBundleDisplayName": "VERAFeedbackApp",
                ].merging(combinedPlistValues()) { _, new in new }),
            sources: ["VERAFeedbackApp/**"],
            scripts: [.swiftLint(targetName: "VERAFeedbackApp")],
            dependencies: [
                .target(name: "VERAFeedback")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAFeedbackTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAFeedbackTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAFeedbackTests/**"],
            dependencies: [
                .target(name: "VERAFeedback"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAFeedbackSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAFeedbackSnapshotTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAFeedbackSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAFeedback"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAFeedbackTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAFeedbackTests"]),
            testAction: .targets(["VERAFeedbackTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAFeedbackSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAFeedbackSnapshotTests"]),
            testAction: .targets(["VERAFeedbackSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
