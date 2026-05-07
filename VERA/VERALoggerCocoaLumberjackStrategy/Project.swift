import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERALoggerCocoaLumberjackStrategy",
    options: defaultProjectOptions(),
    packages: [
        .cocoaLumberjack
    ],
    targets: [
        .target(
            name: "VERALoggerCocoaLumberjackStrategy",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERALoggerCocoaLumberjackStrategy",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERALoggerCocoaLumberjackStrategy/**"],
            scripts: [.swiftLint(targetName: "VERALoggerCocoaLumberjackStrategy")],
            dependencies: [
                .project(target: "VERALogger", path: "../VERALogger"),
                .cocoaLumberjackSwift,
            ],
            settings: createBaseBuildSettings()
        )
    ]
)
