import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAMeetingRoom",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAMeetingRoom",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAMeetingRoom",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAMeetingRoom/**"],
            resources: [
                "VERAMeetingRoom/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERAMeetingRoom")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAMeetingRoomTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAMeetingRoomTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAMeetingRoomTests/**"],
            dependencies: [
                .target(name: "VERAMeetingRoom"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAMeetingRoomSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAMeetingRoom.snapshottests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAMeetingRoomSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAMeetingRoom"),
                .swiftSnapshotTesting,
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAMeetingRoomTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAMeetingRoomTests"]),
            testAction: .targets(["VERAMeetingRoomTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
        .scheme(
            name: "VERAMeetingRoomSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAMeetingRoomSnapshotTests"]),
            testAction: .targets(["VERAMeetingRoomSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
