import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAConfiguration",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAConfiguration",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAConfiguration",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAConfiguration/**"],
            scripts: [.swiftLint(targetName: "VERAConfiguration")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAConfigurationTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAConfigurationTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAConfigurationTests/**"],
            dependencies: [
                .target(name: "VERAConfiguration")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAConfigurationTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAConfigurationTests"]),
            testAction: .targets(["VERAConfigurationTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
