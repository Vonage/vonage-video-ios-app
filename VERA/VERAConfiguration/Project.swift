import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAConfiguration",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERAConfiguration",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAConfiguration",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAConfiguration/**"],
            scripts: [.swiftLint(targetName: "VERAConfiguration")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain")
            ],
            settings: createBaseBuildSettings()
        )
    ]
)
