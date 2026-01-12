import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERADomain",
    targets: [
        .target(
            name: "VERADomain",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERADomain",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERADomain/**"],
            scripts: [.swiftLint(targetName: "VERADomain")],
            settings: createBaseBuildSettings()
        )
    ]
)
