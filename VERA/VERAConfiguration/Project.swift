import ProjectDescription

let project = Project(
    name: "VERAConfiguration",
    targets: [
        .target(
            name: "VERAConfiguration",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAConfiguration",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAConfiguration/**"]
        )
    ]
)
