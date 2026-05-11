// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VonageClientSDKVideo",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "VonageClientSDKVideo",
            targets: ["OpenTok", "VonageClientSDKVideo"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Local unsigned build with Phase 1+2 camera-enumeration changes.
        // For App Store / external distribution this needs to be swapped back to
        // a signed remote `.binaryTarget(url:checksum:)` once the SDK release lands.
        .binaryTarget(name: "OpenTok", path: "OpenTok.xcframework"),
        .target(
            name: "VonageClientSDKVideo",
            path: "Sources",
            resources: [
                .process("VonageClientSDKVideo/Resources/selfie_segmentation.tflite"),
                .copy("VonageClientSDKVideo/Resources/PrivacyInfo.xcprivacy"),
            ],
            linkerSettings: [
                .linkedFramework("Network"),
                .linkedFramework("VideoToolbox"),
                .linkedFramework("Accelerate"),
                .linkedLibrary("c++"),
            ]),
        .testTarget(
            name: "VonageClientSDKVideoTests",
            dependencies: ["VonageClientSDKVideo"]),
    ]
)
