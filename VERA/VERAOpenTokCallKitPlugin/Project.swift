import ProjectDescription

let project = Project(
    name: "VERAOpenTokCallKitPlugin",
    targets: [
        .target(
            name: "VERAOpenTokCallKitPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAOpenTokCallKitPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTokCallKitPlugin/**"],
            dependencies: [
                .project(target: "VERAOpenTok", path: "../VERAOpenTok"),
                .project(target: "VERACore", path: "../VERACore"),
            ]
        ),
        .target(
            name: "VERAOpenTokCallKitPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAOpenTokCallKitPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTokCallKitPluginTests/**"],
            dependencies: [
                .project(target: "VERAOpenTok", path: "../VERAOpenTok"),
                .target(name: "VERAOpenTokCallKitPlugin"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERATestHelpers", path: "../VERACore")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOpenTokCallKitPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOpenTokCallKitPluginTests"]),
            testAction: .targets(["VERAOpenTokCallKitPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
