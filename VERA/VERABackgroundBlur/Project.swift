import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERABackgroundBlur",
    targets: [
        .target(
            name: "VERABackgroundBlur",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERABackgroundBlur",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERABackgroundBlur/**"],
            resources: [
                "VERABackgroundBlur/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERABackgroundBlur")],
            dependencies: [],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERABackgroundBlurTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERABackgroundBlurTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERABackgroundBlurTests/**"],
            dependencies: [
                .target(name: "VERABackgroundBlur")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERABackgroundBlurTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERABackgroundBlurTests"]),
            testAction: .targets(["VERABackgroundBlurTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
