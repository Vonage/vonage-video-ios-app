import Foundation
import ProjectDescription

/// Aggregated test schemes for the workspace, grouped by `xcodebuild` destination.
///
/// Each scheme bundles every test target that shares one destination, so CI can run the
/// whole suite with a single `xcodebuild test` invocation per destination instead of one
/// invocation per module scheme:
/// - `VERAUnitTests-macOS` — unit tests that also build for macOS (no simulator required)
/// - `VERAUnitTests-iOS` — unit tests that need the iOS simulator (Vonage SDK, UIKit, plugins)
/// - `VERASnapshotTests-iOS` — snapshot tests (run serially so rendering stays deterministic)
///
/// Feature-flagged modules are included only when enabled in `Config/app-config.json`,
/// mirroring how the main `Project.swift` wires dependencies.
public enum VERATestSchemes {

    /// All aggregated test schemes, one per CI destination.
    public static func all() -> [Scheme] {
        [
            scheme(name: "VERAUnitTests-macOS", testTargets: macOSUnitTestTargets()),
            scheme(name: "VERAUnitTests-iOS", testTargets: iOSUnitTestTargets()),
            scheme(name: "VERASnapshotTests-iOS", testTargets: snapshotTestTargets()),
        ]
    }

    /// Builds a shared scheme that builds and tests the given targets in one invocation.
    private static func scheme(name: String, testTargets: [TestableTarget]) -> Scheme {
        .scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: testTargets.map(\.target)),
            testAction: .targets(testTargets, configuration: .debug)
        )
    }

    /// Unit test targets that also build for macOS, so CI can run them without a simulator.
    private static func macOSUnitTestTargets() -> [TestableTarget] {
        var targets: [TestableTarget] = [
            testableTarget("VERACoreTests", in: "VERACore"),
            testableTarget("VERADomainTests", in: "VERADomain"),
            testableTarget("VERAMeetingRoomTests", in: "VERAMeetingRoom"),
        ]
        if isOktaEnabled() {
            targets.append(testableTarget("VERAOKTATests", in: "VERAOKTA"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowChat") {
            targets.append(testableTarget("VERAChatTests", in: "VERAChat"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowArchiving") {
            targets.append(testableTarget("VERAArchivingTests", in: "VERAArchiving"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowScreenShare") {
            targets.append(testableTarget("VERAScreenShareTests", in: "VERAScreenShare"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowEmojis") {
            targets.append(testableTarget("VERAReactionsTests", in: "VERAReactions"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowSettings") {
            targets.append(testableTarget("VERASettingsTests", in: "VERASettings"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowFeedback") {
            targets.append(testableTarget("VERAFeedbackTests", in: "VERAFeedback"))
        }
        if isFeatureEnabled("audioSettings", "allowAudioDiagnostics") {
            targets.append(testableTarget("VERAAudioDiagnosticsTests", in: "VERAAudioDiagnostics"))
        }
        return targets
    }

    /// Unit test targets that require the iOS simulator (Vonage SDK, UIKit, plugins).
    private static func iOSUnitTestTargets() -> [TestableTarget] {
        var targets: [TestableTarget] = [
            testableTarget("VERATests", in: "."),
            testableTarget("VERAVonageTests", in: "VERAVonage"),
            testableTarget("VERACommonUITests", in: "VERACommonUI"),
            testableTarget("VERACocoaLumberjackLoggerTests", in: "VERACocoaLumberjackLogger"),
            testableTarget("VERAVonageCallKitPluginTests", in: "VERAVonageCallKitPlugin"),
            testableTarget("VERAMeetingRoomSDKTests", in: "VERAMeetingRoomSDK"),
        ]
        if isFeatureEnabled("meetingRoomSettings", "allowChat") {
            targets.append(testableTarget("VERAVonageChatPluginTests", in: "VERAVonageChatPlugin"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowArchiving") {
            targets.append(testableTarget("VERAVonageArchivingPluginTests", in: "VERAVonageArchivingPlugin"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowSettings") {
            targets.append(testableTarget("VERAVonageSettingsPluginTests", in: "VERAVonageSettingsPlugin"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowScreenShare") {
            targets.append(testableTarget("VERAVonageScreenSharePluginTests", in: "VERAVonageScreenSharePlugin"))
        }
        if isFeatureEnabled("audioSettings", "allowAdvancedNoiseSuppression") {
            targets.append(testableTarget("VERAAudioEffectsTests", in: "VERAAudioEffects"))
        }
        if isFeatureEnabled("videoSettings", "allowBackgroundEffects") {
            targets.append(testableTarget("VERABackgroundEffectsTests", in: "VERABackgroundEffects"))
        }
        if isFeatureEnabled("audioSettings", "allowAudioDiagnostics") {
            targets.append(testableTarget("VERAAudioDiagnosticsTests", in: "VERAAudioDiagnostics"))
        }
        return targets
    }

    /// Snapshot test targets; they run on the iOS simulator and stay non-parallelizable
    /// so rendering is deterministic.
    private static func snapshotTestTargets() -> [TestableTarget] {
        var targets: [TestableTarget] = [
            testableTarget("VERACoreSnapshotTests", in: "VERACore"),
            testableTarget("VERAMeetingRoomSnapshotTests", in: "VERAMeetingRoom"),
            testableTarget("VERACommonUISnapshotTests", in: "VERACommonUI"),
        ]
        if isFeatureEnabled("meetingRoomSettings", "allowChat") {
            targets.append(testableTarget("VERAChatSnapshotTests", in: "VERAChat"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowArchiving") {
            targets.append(testableTarget("VERAArchivingSnapshotTests", in: "VERAArchiving"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowCaptions") {
            targets.append(testableTarget("VERACaptionsSnapshotTests", in: "VERACaptions"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowEmojis") {
            targets.append(testableTarget("VERAReactionsSnapshotTests", in: "VERAReactions"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowSettings") {
            targets.append(testableTarget("VERASettingsSnapshotTests", in: "VERASettings"))
        }
        if isFeatureEnabled("audioSettings", "allowAdvancedNoiseSuppression") {
            targets.append(testableTarget("VERAAudioEffectsSnapshotTests", in: "VERAAudioEffects"))
        }
        if isFeatureEnabled("videoSettings", "allowBackgroundEffects") {
            targets.append(testableTarget("VERABackgroundEffectsSnapshotTests", in: "VERABackgroundEffects"))
        }
        if isFeatureEnabled("meetingRoomSettings", "allowFeedback") {
            targets.append(testableTarget("VERAFeedbackSnapshotTests", in: "VERAFeedback"))
        }
        if isFeatureEnabled("audioSettings", "allowAudioDiagnostics") {
            targets.append(testableTarget("VERAAudioDiagnosticsSnapshotTests", in: "VERAAudioDiagnostics"))
        }
        return targets
    }

    /// Creates a testable target reference for a test target defined in the given module project.
    private static func testableTarget(_ name: String, in projectPath: Path) -> TestableTarget {
        .testableTarget(target: .project(path: projectPath, target: name))
    }

    /// Reads a boolean feature flag from `Config/app-config.json`.
    ///
    /// - Important: Crashes with `fatalError` if the file cannot be read or the key is missing,
    ///   matching the strictness of the config readers in the main `Project.swift`.
    private static func isFeatureEnabled(_ section: String, _ key: String) -> Bool {
        guard let configData = FileManager.default.contents(atPath: "./Config/app-config.json"),
            let json = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
            let settings = json[section] as? [String: Any],
            let value = settings[key] as? Bool
        else {
            fatalError("Could not read \(section).\(key) from app-config.json")
        }
        return value
    }

    /// Returns `true` when `authSettings.idProviders` contains `"okta"` in `app-config.json`.
    private static func isOktaEnabled() -> Bool {
        guard let configData = FileManager.default.contents(atPath: "./Config/app-config.json"),
            let json = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
            let authSettings = json["authSettings"] as? [String: Any],
            let providers = authSettings["idProviders"] as? [String]
        else {
            return false
        }
        return providers.contains("okta")
    }
}
