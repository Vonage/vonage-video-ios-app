import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERALogger",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERALogger",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERALogger",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERALogger/**"],
            scripts: [.swiftLint(targetName: "VERALogger")],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERALoggerTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERALoggerTests",
            deploymentTargets: multiplatformDeploymentTarget,
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
