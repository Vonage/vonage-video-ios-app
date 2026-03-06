import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAScreenShare",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAScreenShare",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAScreenShare",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAScreenShare/**"],
            resources: ["VERAScreenShare/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAScreenShare")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAScreenShareTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAScreenShareTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAScreenShareTests/**"],
            dependencies: [
                .target(name: "VERAScreenShare")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAScreenShareTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAScreenShareTests"]),
            testAction: .targets(["VERAScreenShareTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
