import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageSettingsPlugin",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAVonageSettingsPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageSettingsPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageSettingsPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageSettingsPlugin")],
            dependencies: [
                .project(target: "VERASettings", path: "../VERASettings"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageSettingsPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageSettingsPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageSettingsPluginTests/**"],
            dependencies: [
                .project(target: "VERASettings", path: "../VERASettings"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageSettingsPlugin"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageSettingsPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageSettingsPluginTests"]),
            testAction: .targets(["VERAVonageSettingsPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
