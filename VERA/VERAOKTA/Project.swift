import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAOKTA",
    options: defaultProjectOptions(),
    packages: [
        .oktaMobileSwift
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAOKTA",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAOKTA",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAOKTA/**"],
            resources: ["VERAOKTA/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAOKTA")],
            dependencies: [
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
                .project(target: "VERADomain", path: "../VERADomain"),
                .oktaAuthFoundation,
                .oktaBrowserSignin,
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAOKTATests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAOKTATests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAOKTATests/**"],
            dependencies: [
                .target(name: "VERAOKTA"),
                .project(target: "VERATestHelpers", path: "../VERACore"),
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAOKTATests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAOKTATests"]),
            testAction: .targets(["VERAOKTATests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
