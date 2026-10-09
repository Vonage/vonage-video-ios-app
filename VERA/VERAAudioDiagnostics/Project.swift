import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "VERAAudioDiagnostics",
    options: defaultProjectOptions(),
    packages: [
        .swiftSnapshotTesting
    ],
    targets: [
        // MARK: - Framework Target
        .target(
            name: "VERAAudioDiagnostics",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.vonage.VERAAudioDiagnostics",
            deploymentTargets: multiplatformDeploymentTarget,
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
            deploymentTargets: multiplatformDeploymentTarget,
            sources: ["VERAAudioDiagnosticsTests/**"],
            dependencies: [
                .target(name: "VERAAudioDiagnostics")
            ],
            settings: createBaseBuildSettings()
        ),

        // MARK: - Snapshot Tests Target
        .target(
            name: "VERAAudioDiagnosticsSnapshotTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.vonage.VERAAudioDiagnosticsSnapshotTests",
            deploymentTargets: iOSDeploymentTarget,
            sources: ["VERAAudioDiagnosticsSnapshotTests/**"],
            dependencies: [
                .target(name: "VERAAudioDiagnostics"),
                .swiftSnapshotTesting,
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
        ),
        .scheme(
            name: "VERAAudioDiagnosticsSnapshotTests",
            shared: true,
            buildAction: .buildAction(targets: ["VERAAudioDiagnosticsSnapshotTests"]),
            testAction: .targets(["VERAAudioDiagnosticsSnapshotTests"], configuration: .debug),
            runAction: .runAction(configuration: .debug)
        ),
    ]
)
