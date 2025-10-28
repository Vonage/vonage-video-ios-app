import ProjectDescription

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
            dependencies: [
                .project(target: "VERAChat", path: "../VERAChat"),
                .project(target: "VERAOpenTok", path: "../VERAOpenTok")
            ]
        )
    ]
)
