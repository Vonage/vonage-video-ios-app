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
            deploymentTargets: iOSDeploymentTarget,
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
        )
    ]
)
