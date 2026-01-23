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
        ),
        .target(
            name: "VERADomainTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERADomainTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERADomainTests/**"],
            dependencies: [
                .target(name: "VERADomain")
            ],
            settings: createBaseBuildSettings()
        ),
    ]
)
