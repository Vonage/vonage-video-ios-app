import ProjectDescription

let project = Project(
    name: "VERADomain",
    targets: [
        .target(
            name: "VERADomain",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERADomain",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERADomain/**"]
        )
    ]
)
