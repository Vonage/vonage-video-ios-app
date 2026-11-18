import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACocoaLumberjackLogger",
    options: defaultProjectOptions(),
    packages: [.cocoaLumberjack],
    settings: defaultProjectSettings(),
    targets: [
        .target(
            name: "VERACocoaLumberjackLogger",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACocoaLumberjackLogger",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERACocoaLumberjackLogger/**"],
            scripts: [.swiftLint(targetName: "VERACocoaLumberjackLogger")],
            dependencies: [
                .cocoaLumberjackSwift,
                .project(target: "VERALogger", path: "../VERALogger"),
            ],
            // The generated -Swift.h imports CocoaLumberjack (SPM), which the module verifier can't resolve.
            settings: .settings(base: baseBuildSettings().merging(["ENABLE_MODULE_VERIFIER": "NO"]) { $1 })
        ),
        .target(
            name: "VERACocoaLumberjackLoggerTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACocoaLumberjackLoggerTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERACocoaLumberjackLoggerTests/**"],
            dependencies: [
                .target(name: "VERACocoaLumberjackLogger"),
                .project(target: "VERALogger", path: "../VERALogger"),
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
