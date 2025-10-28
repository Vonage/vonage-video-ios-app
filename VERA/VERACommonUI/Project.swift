import ProjectDescription

let project = Project(
    name: "VERACommonUI",
    targets: [
        .target(
            name: "VERACommonUI",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERACommonUI",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERACommonUI/**"],
            resources: [
                "VERACommonUI/Resources/**",
                "VERACommonUI/Resources/**/*.xcassets"
            ],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
            ]
        )
    ]
)
