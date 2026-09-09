import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageChatPlugin",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAVonageChatPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageChatPlugin",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAVonageChatPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageChatPlugin")],
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageChatPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageChatPluginTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAVonageChatPluginTests/**"],
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAChatAppTestHelpers", path: "../VERAChat"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageChatPlugin"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageChatPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageChatPluginTests"]),
            testAction: .targets(["VERAVonageChatPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
