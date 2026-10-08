import ProjectDescription

extension Package {
    public static let vonageVideoSDK = Package.package(
        url: "https://github.com/Vonage/vonage-video-client-sdk-swift",
        .upToNextMinor(from: DependencyVersions.vonageVideoSDK)
    )
}

extension TargetDependency {
    public static let vonageVideoSDK = TargetDependency.package(product: "VonageClientSDKVideo")

    /// The Vonage Video SDK target dependency along with its required system libraries.
    /// Use this instead of `.vonageVideoSDK` for targets that link the SDK directly,
    /// since Tuist does not propagate linkerSettings from SPM package targets
    /// to the generated Xcode project (see: https://github.com/tuist/tuist/issues/8056).
    public static let vonageVideoSDKDependencies: [TargetDependency] = [
        .vonageVideoSDK,
        .sdk(name: "Network", type: .framework, status: .required),
        .sdk(name: "VideoToolbox", type: .framework, status: .required),
        .sdk(name: "Accelerate", type: .framework, status: .required),
        .sdk(name: "c++", type: .library, status: .required),
    ]
}

extension Package {
    public static let vonageVideoTransformersSDK = Package.package(
        url: "https://github.com/Vonage/vonage-client-sdk-video-transformers",
        .upToNextMinor(from: DependencyVersions.vonageVideoTransformersSDK)
    )
}

extension TargetDependency {
    /// Resolved via Tuist's modern SPM integration (`Tuist/Package.swift`) so the
    /// dynamic transformers framework gets embedded in the app. Do not declare it
    /// as an inline `Package` or in any project's `packages:`.
    public static let vonageVideoTransformersSDK = TargetDependency.external(name: "VonageClientSDKVideoTransformers")

    /// The Vonage Video Transformers SDK target dependency along with its required system libraries.
    /// Use this instead of `.vonageVideoTransformersSDK` for targets that link the SDK directly,
    /// since Tuist does not propagate linkerSettings from SPM package targets
    /// to the generated Xcode project (see: https://github.com/tuist/tuist/issues/8056).
    public static let vonageVideoTransformersSDKDependencies: [TargetDependency] = [
        .vonageVideoTransformersSDK,
        .sdk(name: "VideoToolbox", type: .framework, status: .required),
        .sdk(name: "Accelerate", type: .framework, status: .required),
        .sdk(name: "Network", type: .framework, status: .required),
        .sdk(name: "c++", type: .library, status: .required),
    ]
}

extension Package {
    public static let swiftSnapshotTesting = Package.package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        .upToNextMinor(from: DependencyVersions.swiftSnapshotTesting)
    )
}

extension TargetDependency {
    public static let swiftSnapshotTesting = TargetDependency.package(product: "SnapshotTesting")
}

extension Package {
    public static let cocoaLumberjack = Package.package(
        url: "https://github.com/CocoaLumberjack/CocoaLumberjack",
        .upToNextMajor(from: DependencyVersions.cocoaLumberjack)
    )
}

extension TargetDependency {
    public static let cocoaLumberjackSwift = TargetDependency.package(product: "CocoaLumberjackSwift")
}
