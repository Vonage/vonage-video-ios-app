import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERALogger",
    options: defaultProjectOptions(),
    packages: [
        .cocoaLumberjack,
    ],
    targets: [
        .target(
            name: "VERALogger",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERALogger",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERALogger/**"],
            scripts: [.swiftLint(targetName: "VERALogger")],
            dependencies: [
                .cocoaLumberjackSwift,
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERALoggerTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERALoggerTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERALoggerTests/**"],
            dependencies: [
                .target(name: "VERALogger")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERALoggerTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERALoggerTests"]),
            testAction: .targets(["VERALoggerTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
