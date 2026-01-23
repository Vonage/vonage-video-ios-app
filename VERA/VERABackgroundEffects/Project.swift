import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERABackgroundEffects",
    targets: [
        .target(
            name: "VERABackgroundEffects",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERABackgroundEffects",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERABackgroundEffects/**"],
            resources: [
                "VERABackgroundEffects/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERABackgroundEffects")],
            dependencies: [],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERABackgroundEffectsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERABackgroundEffectsTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERABackgroundEffectsTests/**"],
            dependencies: [
                .target(name: "VERABackgroundEffects")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERABackgroundEffectsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERABackgroundEffectsTests"]),
            testAction: .targets(["VERABackgroundEffectsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
