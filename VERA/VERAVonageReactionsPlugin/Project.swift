import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageReactionsPlugin",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAVonageReactionsPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageReactionsPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageReactionsPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageReactionsPlugin")],
            dependencies: [
                .project(target: "VERAReactions", path: "../VERAReactions"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageReactionsPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageReactionsPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageReactionsPluginTests/**"],
            dependencies: [
                .project(target: "VERAReactions", path: "../VERAReactions"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageReactionsPlugin"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageReactionsPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageReactionsPluginTests"]),
            testAction: .targets(["VERAVonageReactionsPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
