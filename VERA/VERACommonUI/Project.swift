import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERACommonUI",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERACommonUI",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERACommonUI",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACommonUI/**"],
            resources: [
                "VERACommonUI/Resources/**",
                "VERACommonUI/Resources/**/*.xcassets",
            ],
            scripts: [.swiftLint(targetName: "VERACommonUI")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain")
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERACommonUITests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERACommonUITests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERACommonUITests/**"],
            dependencies: [
                .target(name: "VERACommonUI")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERACommonUITests",
            shared: true,
            buildAction: .buildAction(targets: ["VERACommonUITests"]),
            testAction: .targets(["VERACommonUITests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
