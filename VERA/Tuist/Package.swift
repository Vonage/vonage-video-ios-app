// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import ProjectDescription

    // Transformers ships a dynamic binary framework consumed by multiple dynamic
    // frameworks. Modern integration + `.framework` embeds it into the app
    // (the legacy inline `packages:` integration doesn't, causing a dyld crash).
    let packageSettings = PackageSettings(
        productTypes: [
            "VonageClientSDKVideoTransformers": .framework
        ]
    )
#endif

let package = Package(
    name: "VERADependencies",
    dependencies: [
        .package(
            url: "https://github.com/Vonage/vonage-client-sdk-video-transformers",
            .upToNextMinor(from: "2.35.1")
        )
    ]
)
