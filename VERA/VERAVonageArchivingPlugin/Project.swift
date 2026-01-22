import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonageArchivingPlugin",
    targets: [
        .target(
            name: "VERAVonageArchivingPlugin",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonageArchivingPlugin",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageArchivingPlugin/**"],
            scripts: [.swiftLint(targetName: "VERAVonageArchivingPlugin")],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .project(target: "VERAArchiving", path: "../VERAArchiving"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageArchivingPluginTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageArchivingPluginTests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAVonageArchivingPluginTests/**"],
            dependencies: [
                .project(target: "VERAVonage", path: "../VERAVonage"),
                .target(name: "VERAVonageArchivingPlugin"),
                .project(target: "VERAArchiving", path: "../VERAArchiving"),
                .project(target: "VERAArchivingTestHelpers", path: "../VERAArchiving"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageArchivingPluginTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageArchivingPluginTests"]),
            testAction: .targets(["VERAVonageArchivingPluginTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
