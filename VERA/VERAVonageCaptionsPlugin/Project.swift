import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageCaptionsPlugin",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAVonageCaptionsPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageCaptionsPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageCaptionsPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageCaptionsPlugin")],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERACaptions", path: "../VERACaptions"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageCaptionsPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageCaptionsPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageCaptionsPluginTests/**"],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageCaptionsPlugin"),
                .project(target: "VERACaptions", path: "../VERACaptions"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageCaptionsPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageCaptionsPluginTests"]),
            testAction: .targets(["VERAVonageCaptionsPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
