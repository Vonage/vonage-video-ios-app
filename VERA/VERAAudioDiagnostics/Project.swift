import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAAudioDiagnostics",
    options: defaultProjectOptions(),
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAAudioDiagnostics",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAAudioDiagnostics",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAAudioDiagnostics/**"],
            resources: ["VERAAudioDiagnostics/Resources/**"],
            scripts: [.swiftLint(targetName: "VERAAudioDiagnostics")],
            dependencies: [
                .project(target: "VERADomain", path: "../VERADomain"),
                .project(target: "VERACommonUI", path: "../VERACommonUI"),
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Unit Tests Target
        .target(
            name: "VERAAudioDiagnosticsTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "com.vonage.VERAAudioDiagnosticsTests",
            deploymentTargets: DeploymentTargets.multiplatform(iOS: "16.0", macOS: "14.6"),
            sources: ["VERAAudioDiagnosticsTests/**"],
            dependencies: [
                .target(name: "VERAAudioDiagnostics")
            ],
            settings: createBaseBuildSettings()
        ),
    ],
    schemes: [
        .scheme(
            name: "VERAAudioDiagnosticsTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAAudioDiagnosticsTests"]),
            testAction: .targets(["VERAAudioDiagnosticsTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        )
    ]
)
