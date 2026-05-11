import ProjectDescription

extension Package {
    // Local wrapper for an unsigned SDK build with Phase 1+2 camera-enumeration
    // changes (real device list on Mac, new `OTCameraDevice` API). When the
    // upstream SDK ships these changes this can revert to the remote URL.
    public static let vonageVideoSDK = Package.package(
        path: "../Tuist/LocalPackages/vonage-video-client-sdk-swift"
    )
}

extension TargetDependency {
    public static let vonageVideoSDK = TargetDependency.package(product: "VonageClientSDKVideo")
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
