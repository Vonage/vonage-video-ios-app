import ProjectDescription

extension Package {
    public static let vonageVideoSDK = Package.package(
        url: "https://github.com/Vonage/vonage-video-client-sdk-swift",
        .upToNextMinor(from: "2.35.1")
    )
}

extension TargetDependency {
    public static let vonageVideoSDK = TargetDependency.package(product: "VonageClientSDKVideo")

    /// The Vonage Video SDK target dependency along with its required system libraries.
    /// Use this instead of `.vonageVideoSDK` for targets that link the SDK directly,
    /// since Tuist does not propagate linkerSettings from SPM package targets
    /// to the generated Xcode project (see: https://github.com/tuist/tuist/issues/8056).
    public static let vonageVideoSDKWithSystemDependencies: [TargetDependency] = [
        .vonageVideoSDK,
        .sdk(name: "c++", type: .library, status: .required),
    ]
}

extension Package {
    public static let vonageVideoTransformersSDK = Package.package(
        url: "https://github.com/Vonage/vonage-client-sdk-video-transformers",
        .upToNextMinor(from: "2.33")
    )
}

extension TargetDependency {
    public static let vonageVideoTransformersSDK = TargetDependency.package(product: "VonageClientSDKVideoTransformers")
}

extension Package {
    public static let swiftSnapshotTesting = Package.package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing",
        .upToNextMinor(from: "1.18.4")
    )
}

extension TargetDependency {
    public static let swiftSnapshotTesting = TargetDependency.package(product: "SnapshotTesting")
}

extension Package {
    public static let cocoaLumberjack = Package.package(
        url: "https://github.com/CocoaLumberjack/CocoaLumberjack",
        .upToNextMajor(from: "3.8.5")
    )
}

extension TargetDependency {
    public static let cocoaLumberjackSwift = TargetDependency.package(product: "CocoaLumberjackSwift")
}
