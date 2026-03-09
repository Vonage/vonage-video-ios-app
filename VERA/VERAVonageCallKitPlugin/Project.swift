import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageCallKitPlugin",
    targets: [
        .target(
            name: "VERAVonageCallKitPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageCallKitPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageCallKitPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageCallKitPlugin")],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageCallKitPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageCallKitPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageCallKitPluginTests/**"],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageCallKitPlugin"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageCallKitPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageCallKitPluginTests"]),
            testAction: .targets(["VERAVonageCallKitPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
