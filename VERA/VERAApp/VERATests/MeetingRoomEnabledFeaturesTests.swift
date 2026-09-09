//
//  Created by Vonage on 8/9/26.
//

import Foundation
import Testing
import VERAConfiguration
import VERATestHelpers

@testable import VERA
@testable import VERAMeetingRoomSDK

/// Validates that `DependencyContainer.meetingRoomEnabledFeatures` derives the correct
/// `Set<MeetingRoomFeature>` from `AppConfig` — i.e. that editing `app-config.json` and
/// running setup activates / deactivates the meeting room features as expected.
///
/// - Note: These tests run on the iOS destination, so `pictureInPicture` (gated by
///   `#if !os(macOS)`) and `screenShare` (gated by `!isiOSAppOnMac`) are expected to be
///   enabled when their flags are `true`.
@Suite("Meeting room enabled features")
struct MeetingRoomEnabledFeaturesTests {

    // MARK: - Full configurations

    @Test("All flags enabled activates every feature")
    func allFlagsEnabledActivatesEveryFeature() {
        let sut = makeContainer(
            backgroundEffects: true,
            advancedNoiseSuppression: true,
            audioDiagnostics: true,
            archiving: true,
            captions: true,
            chat: true,
            emojis: true,
            feedback: true,
            pictureInPicture: true,
            screenShare: true,
            settings: true)

        #expect(sut.meetingRoomEnabledFeatures == Set(MeetingRoomFeature.allCases))
    }

    @Test("All flags disabled leaves only callKit")
    func allFlagsDisabledLeavesOnlyCallKit() {
        let sut = makeContainer()

        #expect(sut.meetingRoomEnabledFeatures == [.callKit])
    }

    @Test("A realistic mixed configuration activates exactly its features")
    func mixedConfigurationActivatesExactlyItsFeatures() {
        // chat + captions + reactions + screen share + background effects on;
        // everything else off.
        let sut = makeContainer(
            backgroundEffects: true,
            captions: true,
            chat: true,
            emojis: true,
            screenShare: true)

        #expect(
            sut.meetingRoomEnabledFeatures == [
                .chat,
                .captions,
                .reactions,
                .screenShare,
                .backgroundEffects,
                .callKit,
            ])
    }

    // MARK: - callKit is always present

    @Test("callKit is always enabled regardless of configuration")
    func callKitIsAlwaysEnabled() {
        #expect(makeContainer().meetingRoomEnabledFeatures.contains(.callKit))
        #expect(makeContainer(chat: true).meetingRoomEnabledFeatures.contains(.callKit))

        let all = makeContainer(
            backgroundEffects: true,
            advancedNoiseSuppression: true,
            audioDiagnostics: true,
            archiving: true,
            captions: true,
            chat: true,
            emojis: true,
            feedback: true,
            pictureInPicture: true,
            screenShare: true,
            settings: true)
        #expect(all.meetingRoomEnabledFeatures.contains(.callKit))
    }

    // MARK: - One flag at a time

    /// Every toggleable meeting room flag, paired with the feature it should enable.
    static let singleFeatureCases: [MeetingRoomFeature] =
        MeetingRoomFeature.allCases.filter { $0 != .callKit }

    @Test(
        "Enabling a single flag activates exactly that feature plus callKit",
        arguments: singleFeatureCases)
    func singleFlagActivatesExactlyThatFeature(_ feature: MeetingRoomFeature) {
        let sut = makeContainerEnablingOnly(feature)

        #expect(sut.meetingRoomEnabledFeatures == [feature, .callKit])
    }

    // MARK: - Individual flag mapping (explicit, for readability)

    @Test("allChat maps to .chat")
    func chatMapping() {
        #expect(makeContainer(chat: true).meetingRoomEnabledFeatures.contains(.chat))
        #expect(!makeContainer(chat: false).meetingRoomEnabledFeatures.contains(.chat))
    }

    @Test("allowEmojis maps to .reactions")
    func emojisMapToReactions() {
        #expect(makeContainer(emojis: true).meetingRoomEnabledFeatures.contains(.reactions))
        #expect(!makeContainer(emojis: false).meetingRoomEnabledFeatures.contains(.reactions))
    }

    @Test("allowAdvancedNoiseSuppression maps to .audioEffects")
    func advancedNoiseSuppressionMapsToAudioEffects() {
        #expect(
            makeContainer(advancedNoiseSuppression: true)
                .meetingRoomEnabledFeatures.contains(.audioEffects))
        #expect(
            !makeContainer(advancedNoiseSuppression: false)
                .meetingRoomEnabledFeatures.contains(.audioEffects))
    }

    @Test("allowBackgroundEffects maps to .backgroundEffects")
    func backgroundEffectsMapping() {
        #expect(
            makeContainer(backgroundEffects: true)
                .meetingRoomEnabledFeatures.contains(.backgroundEffects))
        #expect(
            !makeContainer(backgroundEffects: false)
                .meetingRoomEnabledFeatures.contains(.backgroundEffects))
    }

    // MARK: - Driven by the real app-config.json

    @Test("app-config.json decodes and drives the enabled features consistently")
    func featuresMatchRealAppConfigJSON() throws {
        let json = try Self.loadAppConfigFixture()

        let sut = makeContainer(
            backgroundEffects: json.videoSettings.allowBackgroundEffects,
            advancedNoiseSuppression: json.audioSettings.allowAdvancedNoiseSuppression,
            audioDiagnostics: json.audioSettings.allowAudioDiagnostics,
            archiving: json.meetingRoomSettings.allowArchiving,
            captions: json.meetingRoomSettings.allowCaptions,
            chat: json.meetingRoomSettings.allowChat,
            emojis: json.meetingRoomSettings.allowEmojis,
            feedback: json.meetingRoomSettings.allowFeedback,
            pictureInPicture: json.meetingRoomSettings.allowPictureInPicture,
            screenShare: json.meetingRoomSettings.allowScreenShare,
            settings: json.meetingRoomSettings.allowSettings)

        let features = sut.meetingRoomEnabledFeatures

        // Each feature must be present exactly when its JSON flag is `true`.
        #expect(features.contains(.chat) == json.meetingRoomSettings.allowChat)
        #expect(features.contains(.archiving) == json.meetingRoomSettings.allowArchiving)
        #expect(features.contains(.captions) == json.meetingRoomSettings.allowCaptions)
        #expect(features.contains(.reactions) == json.meetingRoomSettings.allowEmojis)
        #expect(features.contains(.settings) == json.meetingRoomSettings.allowSettings)
        #expect(features.contains(.feedback) == json.meetingRoomSettings.allowFeedback)
        #expect(features.contains(.pictureInPicture) == json.meetingRoomSettings.allowPictureInPicture)
        #expect(features.contains(.screenShare) == json.meetingRoomSettings.allowScreenShare)
        #expect(features.contains(.backgroundEffects) == json.videoSettings.allowBackgroundEffects)
        #expect(features.contains(.audioEffects) == json.audioSettings.allowAdvancedNoiseSuppression)
        #expect(features.contains(.audioDiagnostics) == json.audioSettings.allowAudioDiagnostics)

        // callKit is always on, independent of the JSON.
        #expect(features.contains(.callKit))
    }

    @Test("Every feature declared enabled in app-config.json is active at runtime")
    func jsonEnabledFlagsBecomeActiveFeatures() throws {
        // Builds the expected feature set directly from the JSON flags, then checks the
        // runtime set matches it exactly — so whatever the shipped config declares (some
        // on, some off) is reflected 1:1 in the enabled meeting room features.
        let json = try Self.loadAppConfigFixture()

        var expected: Set<MeetingRoomFeature> = [.callKit]
        if json.meetingRoomSettings.allowChat { expected.insert(.chat) }
        if json.meetingRoomSettings.allowArchiving { expected.insert(.archiving) }
        if json.meetingRoomSettings.allowCaptions { expected.insert(.captions) }
        if json.meetingRoomSettings.allowEmojis { expected.insert(.reactions) }
        if json.meetingRoomSettings.allowSettings { expected.insert(.settings) }
        if json.meetingRoomSettings.allowFeedback { expected.insert(.feedback) }
        if json.meetingRoomSettings.allowPictureInPicture { expected.insert(.pictureInPicture) }
        if json.meetingRoomSettings.allowScreenShare { expected.insert(.screenShare) }
        if json.videoSettings.allowBackgroundEffects { expected.insert(.backgroundEffects) }
        if json.audioSettings.allowAdvancedNoiseSuppression { expected.insert(.audioEffects) }
        if json.audioSettings.allowAudioDiagnostics { expected.insert(.audioDiagnostics) }

        let sut = makeContainer(
            backgroundEffects: json.videoSettings.allowBackgroundEffects,
            advancedNoiseSuppression: json.audioSettings.allowAdvancedNoiseSuppression,
            audioDiagnostics: json.audioSettings.allowAudioDiagnostics,
            archiving: json.meetingRoomSettings.allowArchiving,
            captions: json.meetingRoomSettings.allowCaptions,
            chat: json.meetingRoomSettings.allowChat,
            emojis: json.meetingRoomSettings.allowEmojis,
            feedback: json.meetingRoomSettings.allowFeedback,
            pictureInPicture: json.meetingRoomSettings.allowPictureInPicture,
            screenShare: json.meetingRoomSettings.allowScreenShare,
            settings: json.meetingRoomSettings.allowSettings)

        #expect(sut.meetingRoomEnabledFeatures == expected)
    }
}

// MARK: - Helpers

extension MeetingRoomEnabledFeaturesTests {

    /// Builds a `DependencyContainer` whose `appConfig` reflects the given feature flags.
    /// Every flag defaults to `false` so each test only opts into what it needs.
    fileprivate func makeContainer(
        backgroundEffects: Bool = false,
        advancedNoiseSuppression: Bool = false,
        audioDiagnostics: Bool = false,
        archiving: Bool = false,
        captions: Bool = false,
        chat: Bool = false,
        emojis: Bool = false,
        feedback: Bool = false,
        pictureInPicture: Bool = false,
        screenShare: Bool = false,
        settings: Bool = false
    ) -> DependencyContainer {
        let config = AppConfig(
            videoSettings: AppConfig.VideoSettings(
                allowBackgroundEffects: backgroundEffects),
            audioSettings: AppConfig.AudioSettings(
                allowAdvancedNoiseSuppression: advancedNoiseSuppression,
                allowAudioDiagnostics: audioDiagnostics),
            meetingRoomSettings: AppConfig.MeetingRoomSettings(
                allowArchiving: archiving,
                allowCaptions: captions,
                allowChat: chat,
                allowEmojis: emojis,
                allowFeedback: feedback,
                allowPictureInPicture: pictureInPicture,
                allowScreenShare: screenShare,
                allowSettings: settings))

        let container = DependencyContainer(httpClient: MockHTTPClient())
        container.appConfig = config
        return container
    }

    /// Builds a container that enables exactly one feature (plus the always-on `callKit`).
    fileprivate func makeContainerEnablingOnly(_ feature: MeetingRoomFeature) -> DependencyContainer {
        switch feature {
        case .chat: return makeContainer(chat: true)
        case .archiving: return makeContainer(archiving: true)
        case .captions: return makeContainer(captions: true)
        case .reactions: return makeContainer(emojis: true)
        case .settings: return makeContainer(settings: true)
        case .feedback: return makeContainer(feedback: true)
        case .pictureInPicture: return makeContainer(pictureInPicture: true)
        case .screenShare: return makeContainer(screenShare: true)
        case .backgroundEffects: return makeContainer(backgroundEffects: true)
        case .audioEffects: return makeContainer(advancedNoiseSuppression: true)
        case .audioDiagnostics: return makeContainer(audioDiagnostics: true)
        case .callKit: return makeContainer()
        }
    }
}

// MARK: - app-config.json fixture

extension MeetingRoomEnabledFeaturesTests {

    /// Loads and decodes the repository's `VERA/Config/app-config.json`.
    ///
    /// The file is located relative to this test's source path (`#filePath`). The iOS
    /// simulator shares the host filesystem, so the source-tree JSON is readable at test
    /// time — the same approach the repo's snapshot tests use for `__Snapshots__`.
    fileprivate static func loadAppConfigFixture() throws -> AppConfigFixture {
        let configURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // VERATests/
            .deletingLastPathComponent()  // VERAApp/
            .deletingLastPathComponent()  // VERA/
            .appendingPathComponent("Config/app-config.json")

        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(AppConfigFixture.self, from: data)
    }
}

/// Mirrors only the keys of `app-config.json` that drive meeting room features.
/// Unknown keys (metadata, baseApiUrl, layout, etc.) are ignored by `Decodable`.
struct AppConfigFixture: Decodable {
    struct VideoSettings: Decodable {
        let allowBackgroundEffects: Bool
    }

    struct AudioSettings: Decodable {
        let allowAdvancedNoiseSuppression: Bool
        let allowAudioDiagnostics: Bool
    }

    struct MeetingRoomSettings: Decodable {
        let allowArchiving: Bool
        let allowCaptions: Bool
        let allowChat: Bool
        let allowEmojis: Bool
        let allowFeedback: Bool
        let allowPictureInPicture: Bool
        let allowScreenShare: Bool
        let allowSettings: Bool
    }

    let videoSettings: VideoSettings
    let audioSettings: AudioSettings
    let meetingRoomSettings: MeetingRoomSettings
}
