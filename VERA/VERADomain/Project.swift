import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERADomain",
    options: defaultProjectOptions(),
    targets: [
        .target(
            name: "VERADomain",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERADomain",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERADomain/**"],
            scripts: [.swiftLint(targetName: "VERADomain")],
            settings: createBaseBuildSettings()
        ),
        .target(
            name: "VERADomainTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERADomainTests",
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERADomainTests/**"],
            dependencies: [
                .target(name: "VERADomain")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERADomainTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERADomainTests"]),
            testAction: .targets(["VERADomainTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
