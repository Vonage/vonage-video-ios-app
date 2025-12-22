import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAConfiguration",
    targets: [
        .target(
            name: "VERAConfiguration",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAConfiguration",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAConfiguration/**"],
            scripts: [.swiftLint],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain")
            ],
            settings: createBaseBuildSettings()
        )
    ]
)
