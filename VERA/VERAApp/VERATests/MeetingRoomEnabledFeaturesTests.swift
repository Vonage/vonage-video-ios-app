//
//  Created by Vonage on 8/9/26.
//

import Foundation
import Testing
import VERAConfiguration

@testable import VERA
@testable import VERAMeetingRoomSDK

/// Validates that `DependencyContainer.meetingRoomEnabledFeatures` derives the correct
/// `Set<MeetingRoomFeature>` from `AppConfig` — i.e. that editing `app-config.json` and
/// running setup activates / deactivates the meeting room features as expected.
///
/// - Note: These tests run on the iOS destination, so `pictureInPicture` (gated by
///   `#if !os(macOS)`) and `screenShare` (gated by `!isiOSAppOnMac`) are expected to be
///   enabled when their flags are `true`. `callKit` is not driven by a flag: it is active
///   on a device and inactive on the simulator, see ``callKitFeatures``.
@Suite("Meeting room enabled features")
struct MeetingRoomEnabledFeaturesTests {

    /// `callKit` is part of every enabled set except on the iOS Simulator, where
    /// `DependencyContainer.isCallKitSupported` is `false`.
    static let callKitFeatures: Set<MeetingRoomFeature> = {
        #if targetEnvironment(simulator)
            return []
        #else
            return [.callKit]
        #endif
    }()

    // MARK: - Full configurations

    @Test("All flags enabled activates every feature")
    func allFlagsEnabledActivatesEveryFeature() {
        let sut = makeContainer(
            backgroundEffects: true,
            advancedNoiseSuppression: true,
            audioDiagnostics: true,
            archiving: true,
            captions: true,
            captionTranslation: true,
            chat: true,
            emojis: true,
            feedback: true,
            pictureInPicture: true,
            postCallTranscription: true,
            screenShare: true,
            settings: true)

        let flagDriven = Set(MeetingRoomFeature.allCases).subtracting([.callKit])
        #expect(sut.meetingRoomEnabledFeatures == flagDriven.union(Self.callKitFeatures))
    }

    @Test("All flags disabled leaves only the platform's callKit support")
    func allFlagsDisabledLeavesOnlyCallKit() {
        let sut = makeContainer()

        #expect(sut.meetingRoomEnabledFeatures == Self.callKitFeatures)
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
            sut.meetingRoomEnabledFeatures
                == Set<MeetingRoomFeature>([.chat, .captions, .reactions, .screenShare, .backgroundEffects])
                .union(Self.callKitFeatures))
    }

    // MARK: - callKit depends only on platform support

    @Test("callKit follows platform support regardless of configuration")
    func callKitFollowsPlatformSupport() {
        let expected = !Self.callKitFeatures.isEmpty

        #expect(makeContainer().meetingRoomEnabledFeatures.contains(.callKit) == expected)
        #expect(makeContainer(chat: true).meetingRoomEnabledFeatures.contains(.callKit) == expected)

        let all = makeContainer(
            backgroundEffects: true,
            advancedNoiseSuppression: true,
            audioDiagnostics: true,
            archiving: true,
            captions: true,
            captionTranslation: true,
            chat: true,
            emojis: true,
            feedback: true,
            pictureInPicture: true,
            postCallTranscription: true,
            screenShare: true,
            settings: true)
        #expect(all.meetingRoomEnabledFeatures.contains(.callKit) == expected)
    }

    // MARK: - One flag at a time

    /// Every toggleable meeting room flag, paired with the feature it should enable.
    static let singleFeatureCases: [MeetingRoomFeature] =
        MeetingRoomFeature.allCases.filter { $0 != .callKit }

    @Test(
        "Enabling a single flag activates exactly that feature plus the platform's callKit support",
        arguments: singleFeatureCases)
    func singleFlagActivatesExactlyThatFeature(_ feature: MeetingRoomFeature) {
        let sut = makeContainerEnablingOnly(feature)

        #expect(sut.meetingRoomEnabledFeatures == Set([feature]).union(Self.callKitFeatures))
    }

    // MARK: - Individual flag mapping (explicit, for readability)

    @Test("allChat maps to .chat")
    func chatMapping() {
        #expect(makeContainer(chat: true).meetingRoomEnabledFeatures.contains(.chat))
        #expect(!makeContainer(chat: false).meetingRoomEnabledFeatures.contains(.chat))
    }

    @Test("allowCaptionTranslation maps to .captionsTranslation")
    func captionTranslationMapsToCaptionsTranslation() {
        #expect(
            makeContainer(captionTranslation: true)
                .meetingRoomEnabledFeatures.contains(.captionsTranslation))
        #expect(
            !makeContainer(captionTranslation: false)
                .meetingRoomEnabledFeatures.contains(.captionsTranslation))
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

    @Test("allowPostCallTranscription maps to .postCallTranscription")
    func postCallTranscriptionMapping() {
        #expect(
            makeContainer(postCallTranscription: true)
                .meetingRoomEnabledFeatures.contains(.postCallTranscription))
        #expect(
            !makeContainer(postCallTranscription: false)
                .meetingRoomEnabledFeatures.contains(.postCallTranscription))
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
            captionTranslation: json.meetingRoomSettings.allowCaptionTranslation,
            chat: json.meetingRoomSettings.allowChat,
            emojis: json.meetingRoomSettings.allowEmojis,
            feedback: json.meetingRoomSettings.allowFeedback,
            pictureInPicture: json.meetingRoomSettings.allowPictureInPicture,
            postCallTranscription: json.meetingRoomSettings.allowPostCallTranscription,
            screenShare: json.meetingRoomSettings.allowScreenShare,
            settings: json.meetingRoomSettings.allowSettings)

        let features = sut.meetingRoomEnabledFeatures

        // Each feature must be present exactly when its JSON flag is `true`.
        #expect(features.contains(.chat) == json.meetingRoomSettings.allowChat)
        #expect(features.contains(.archiving) == json.meetingRoomSettings.allowArchiving)
        #expect(
            features.contains(.postCallTranscription) == json.meetingRoomSettings.allowPostCallTranscription)
        #expect(features.contains(.captions) == json.meetingRoomSettings.allowCaptions)
        #expect(features.contains(.captionsTranslation) == json.meetingRoomSettings.allowCaptionTranslation)
        #expect(features.contains(.reactions) == json.meetingRoomSettings.allowEmojis)
        #expect(features.contains(.settings) == json.meetingRoomSettings.allowSettings)
        #expect(features.contains(.feedback) == json.meetingRoomSettings.allowFeedback)
        #expect(features.contains(.pictureInPicture) == json.meetingRoomSettings.allowPictureInPicture)
        #expect(features.contains(.screenShare) == json.meetingRoomSettings.allowScreenShare)
        #expect(features.contains(.backgroundEffects) == json.videoSettings.allowBackgroundEffects)
        #expect(features.contains(.audioEffects) == json.audioSettings.allowAdvancedNoiseSuppression)
        #expect(features.contains(.audioDiagnostics) == json.audioSettings.allowAudioDiagnostics)

        // callKit follows platform support, independent of the JSON.
        #expect(features.contains(.callKit) == !Self.callKitFeatures.isEmpty)
    }

    @Test("Every feature declared enabled in app-config.json is active at runtime")
    func jsonEnabledFlagsBecomeActiveFeatures() throws {
        // Builds the expected feature set directly from the JSON flags, then checks the
        // runtime set matches it exactly — so whatever the shipped config declares (some
        // on, some off) is reflected 1:1 in the enabled meeting room features.
        let json = try Self.loadAppConfigFixture()

        var expected: Set<MeetingRoomFeature> = Self.callKitFeatures
        if json.meetingRoomSettings.allowChat { expected.insert(.chat) }
        if json.meetingRoomSettings.allowArchiving { expected.insert(.archiving) }
        if json.meetingRoomSettings.allowPostCallTranscription { expected.insert(.postCallTranscription) }
        if json.meetingRoomSettings.allowCaptions { expected.insert(.captions) }
        if json.meetingRoomSettings.allowCaptionTranslation { expected.insert(.captionsTranslation) }
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
            captionTranslation: json.meetingRoomSettings.allowCaptionTranslation,
            chat: json.meetingRoomSettings.allowChat,
            emojis: json.meetingRoomSettings.allowEmojis,
            feedback: json.meetingRoomSettings.allowFeedback,
            pictureInPicture: json.meetingRoomSettings.allowPictureInPicture,
            postCallTranscription: json.meetingRoomSettings.allowPostCallTranscription,
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
        captionTranslation: Bool = false,
        chat: Bool = false,
        emojis: Bool = false,
        feedback: Bool = false,
        pictureInPicture: Bool = false,
        postCallTranscription: Bool = false,
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
                allowCaptionTranslation: captionTranslation,
                allowChat: chat,
                allowEmojis: emojis,
                allowFeedback: feedback,
                allowPictureInPicture: pictureInPicture,
                allowPostCallTranscription: postCallTranscription,
                allowScreenShare: screenShare,
                allowSettings: settings))

        let container = DependencyContainer()
        container.appConfig = config
        return container
    }

    /// Builds a container that enables exactly one feature flag (callKit is platform-driven).
    fileprivate func makeContainerEnablingOnly(_ feature: MeetingRoomFeature) -> DependencyContainer {
        switch feature {
        case .chat: return makeContainer(chat: true)
        case .archiving: return makeContainer(archiving: true)
        case .postCallTranscription: return makeContainer(postCallTranscription: true)
        case .captions: return makeContainer(captions: true)
        case .captionsTranslation: return makeContainer(captionTranslation: true)
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
        let allowCaptionTranslation: Bool
        let allowChat: Bool
        let allowEmojis: Bool
        let allowFeedback: Bool
        let allowPictureInPicture: Bool
        let allowPostCallTranscription: Bool
        let allowScreenShare: Bool
        let allowSettings: Bool
    }

    let videoSettings: VideoSettings
    let audioSettings: AudioSettings
    let meetingRoomSettings: MeetingRoomSettings
}
