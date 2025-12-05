import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAOpenTokChatPlugin",
    targets: [
        .target(
            name: "VERAOpenTokChatPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAOpenTokChatPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTokChatPlugin/**"],
            scripts: [.swiftLint],
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAOpenTok", path: "../VERAOpenTok"),
            ]
        ),
        .target(
            name: "VERAOpenTokChatPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAOpenTokChatPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAOpenTokChatPluginTests/**"],
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAChatAppTestHelpers", path: "../VERAChat"),
                .project(target: "VERAOpenTok", path: "../VERAOpenTok"),
                .target(name: "VERAOpenTokChatPlugin"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOpenTokChatPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOpenTokChatPluginTests"]),
            testAction: .targets(["VERAOpenTokChatPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
