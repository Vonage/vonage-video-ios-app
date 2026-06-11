import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAE2E",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAE2E",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAE2E",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAE2E/**"],
            scripts: [.swiftLint(targetName: "VERAE2E")],
            dependencies: [
                .project(target: "VERAArchiving", path: "../VERAArchiving"),
                .project(target: "VERACore", path: "../VERACore"),
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERAMeetingRoomSDK", path: "../VERAMeetingRoomSDK"),
                .project(target: "VERAVonage", path: "../VERAVonage"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAE2ETests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAE2ETests",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAE2ETests/**"],
            dependencies: [
                .target(name: "VERAE2E"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAE2ETests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAE2ETests"]),
            testAction: .targets(["VERAE2ETests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
