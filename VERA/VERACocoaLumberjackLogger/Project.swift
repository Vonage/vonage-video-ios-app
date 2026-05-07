import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACocoaLumberjackLogger",
    options: defaultProjectOptions(),
    packages: [.cocoaLumberjack],
    targets: [
        .target(
            name: "VERACocoaLumberjackLogger",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACocoaLumberjackLogger",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACocoaLumberjackLogger/**"],
            scripts: [.swiftLint(targetName: "VERACocoaLumberjackLogger")],
            dependencies: [
                .cocoaLumberjackSwift
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACocoaLumberjackLoggerTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACocoaLumberjackLoggerTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACocoaLumberjackLoggerTests/**"],
            dependencies: [
                .target(name: "VERACocoaLumberjackLogger")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERACocoaLumberjackLoggerTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACocoaLumberjackLoggerTests"]),
            testAction: .targets(["VERACocoaLumberjackLoggerTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
