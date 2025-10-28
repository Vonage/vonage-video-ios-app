import ProjectDescription

let project = Project(
    name: "VERACore",
    targets: [
        .target(
            name: "VERACore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERACore",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERACore/**"],
            resources: [
                "VERACore/Resources/**",
                "VERACore/Resources/**/*.xcassets"
            ],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI")
            ]
        )
    ]
)
