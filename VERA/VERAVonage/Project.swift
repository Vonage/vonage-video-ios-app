import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAVonage",
    options: defaultProjectOptions(),
    packages: [
        .vonageVideoSDK
    ],
    targets: [
        .target(
            name: "VERAVonage",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAVonage",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAVonage/**"],
            scripts: [.swiftLint(targetName: "VERAVonage")],
            dependencies: [
                .project(target: "VERACore", path: "../VERACore")
            ] + TargetDependency.vonageVideoSDKWithSystemDependencies,
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAVonageTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAVonageTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAVonageTests/**"],
            dependencies: [
                .target(name: "VERAVonage"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
                .project(target: "VERAMeetingRoom", path: "../VERAMeetingRoom"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAVonageTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAVonageTests"]),
            testAction: .targets(["VERAVonageTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
