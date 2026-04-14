import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAMeetingRoom",
    options: defaultProjectOptions(),
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAMeetingRoom",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAMeetingRoom",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAMeetingRoom/**"],
            scripts: [.swiftLint(targetName: "VERAMeetingRoom")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAMeetingRoomTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAMeetingRoomTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAMeetingRoomTests/**"],
            dependencies: [
                .target(name: "VERAMeetingRoom"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
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
        )
    ]
)
