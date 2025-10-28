import ProjectDescription

let project = Project(
    name: "VERAChat",
    targets: [
        .target(
            name: "VERAChat",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAChat",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAChat/**"],
            resources: [
                "VERAChat/Resources/**"
            ],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
            ]
        ),
        .target(
            name: "VERAChatAppTestHelpers",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.vonage.VERAChatAppTestHelpers",
            deploymentTargets: DeploymentTargets.iOS("16.0"),
            sources: ["VERAChatAppTestHelpers/**"],
            dependencies: [
                .project(target: "VERAChat", path: ".")
            ]
        ),
        .target(
            name: "VERAChatApp",
            destinations: .iOS,
            product: .app,
            bundleId: "com.vonage.VERAChatApp",
            sources: ["VERAChatApp/**"],
            dependencies: [
                .project(target: "VERAChat", path: "."),
                .project(target: "VERAChatAppTestHelpers", path: ".")
            ]
        )
    ]
)
