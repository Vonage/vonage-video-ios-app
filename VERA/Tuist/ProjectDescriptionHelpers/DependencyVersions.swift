// Versions come from VERA/Dependencies.json. Vonage SDKs must be bumped together.

import Foundation
import ProjectDescription

extension String {
    /// Converts a "MAJOR.MINOR.PATCH" string into a Tuist `Version`.
    fileprivate var version: Version {
        guard let version = Version(string: self) else { fatalError("Invalid version '\(self)' in Dependencies.json") }
        return version
    }
}

// MARK: - Dependencies.json models

/// Root layout of Dependencies.json.
private struct Dependencies: Decodable {
    let vonage: VonageSDKVersions
    let thirdParty: ThirdPartyVersions
}

/// `vonage` key: Vonage Client SDKs, always released with the same version.
/// Mirrored in the root Package.swift (SPM can't import Tuist helpers); keep both in sync.
private struct VonageSDKVersions: Decodable {
    let videoSDK: String
    let videoTransformersSDK: String
}

/// `thirdParty` key: every non-Vonage dependency.
private struct ThirdPartyVersions: Decodable {
    let swiftSnapshotTesting: String
    let cocoaLumberjack: String
    let oktaMobileSwift: String
}

// MARK: - Public API

/// Typed dependency versions used by the `Package+*.swift` helpers.
public enum DependencyVersions {
    public static let vonageVideoSDK = dependencies.vonage.videoSDK.version
    public static let vonageVideoTransformersSDK = dependencies.vonage.videoTransformersSDK.version
    public static let swiftSnapshotTesting = dependencies.thirdParty.swiftSnapshotTesting.version
    public static let cocoaLumberjack = dependencies.thirdParty.cocoaLumberjack.version
    public static let oktaMobileSwift = dependencies.thirdParty.oktaMobileSwift.version

    /// Decoded once on first access (static lets are lazy).
    private static let dependencies: Dependencies = {
        // ProjectDescriptionHelpers/ -> Tuist/ -> VERA/Dependencies.json
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Dependencies.json")
        do {
            return try JSONDecoder().decode(Dependencies.self, from: Data(contentsOf: url))
        } catch {
            fatalError("Invalid \(url.path): \(error)")
        }
    }()
}
