import ProjectDescription

extension Package {
    public static let vonageVideoSDK = Package.package(
        url: "https://github.com/Vonage/vonage-video-client-sdk-swift",
        .upToNextMinor(from: "2.32.1")
    )
}

extension TargetDependency {
    public static let vonageVideoSDK = TargetDependency.package(product: "VonageClientSDKVideo")
}

extension Package {
    public static let vonageVideoTransformersSDK = Package.package(
        url: "https://github.com/Vonage/vonage-client-sdk-video-transformers",
        .upToNextMinor(from: "2.32.1")
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
