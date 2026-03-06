import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAArchiving",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAArchiving",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAArchiving",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAArchiving/**"],
            resources: [
                "VERAArchiving/Resources/**"
            ],
            scripts: [.swiftLint(targetName: "VERAArchiving")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAArchivingTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAArchivingTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAArchivingTests/**"],
            dependencies: [
                .target(name: "VERAArchiving"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
                .project(target: "VERAArchivingTestHelpers", path: "../VERAArchiving"),
            ],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERAArchivingTestHelpers",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAArchivingTestHelpers",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAArchivingTestHelpers/**"],
            dependencies: [
                .target(name: "VERAArchiving")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAArchivingTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAArchivingTests"]),
            testAction: .targets(["VERAArchivingTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
