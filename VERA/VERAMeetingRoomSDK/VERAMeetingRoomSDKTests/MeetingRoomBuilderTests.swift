//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERABackgroundEffects
import VERACommonUI
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomBuilder tests")
struct MeetingRoomBuilderTests {

    let testBaseURL = URL(string: "https://api.example.com")!
    let testRoomName: String = "test-room"

    @Test("Builder stores baseURL")
    func builderStoresBaseURL() {
        let builder = makeMeetingRoomBuilder()
            .baseURL(testBaseURL)
        #expect(builder.currentBaseURL == testBaseURL)
    }

    @Test("Builder stores roomName")
    func builderStoresRoomName() {
        let builder = makeMeetingRoomBuilder()
            .roomName(testRoomName)
        #expect(builder.currentRoomName == testRoomName)
    }

    @Test("Builder stores configuration")
    func builderStoresConfiguration() {
        let config = MeetingRoomConfiguration(
            allowMicrophoneControl: false,
            allowCameraControl: true,
            showParticipantList: false
        )
        let builder = makeMeetingRoomBuilder()
            .configuration(config)
        #expect(builder.currentConfiguration == config)
    }

    @Test("Builder stores enabled features")
    func builderStoresEnabledFeatures() {
        let features: Set<MeetingRoomFeature> = [.chat, .captions, .reactions]
        let builder = makeMeetingRoomBuilder()
            .enabledFeatures(features)
        #expect(builder.currentEnabledFeatures == features)
    }

    @Test("Builder defaults to empty feature set")
    func builderDefaultsToEmptyFeatures() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentEnabledFeatures.isEmpty)
    }

    @Test("Builder defaults to standard MeetingRoomConfiguration")
    func builderDefaultsToStandardConfiguration() {
        let builder = makeMeetingRoomBuilder()
        let defaultConfig = MeetingRoomConfiguration()
        #expect(builder.currentConfiguration == defaultConfig)
    }

    @Test("Builder supports chaining all methods")
    func builderSupportsChaining() {
        let builder = makeMeetingRoomBuilder()
            .baseURL(testBaseURL)
            .roomName(testRoomName)
            .configuration(.init(allowMicrophoneControl: false))
            .enabledFeatures([.chat, .archiving])
            .onAction { _ in }
            .appGroupIdentifier("group.com.test")
            .broadcastExtensionBundleId("com.test.broadcast")

        #expect(builder.currentBaseURL == testBaseURL)
        #expect(builder.currentRoomName == testRoomName)
        #expect(builder.currentEnabledFeatures == [.chat, .archiving])
    }

    @Test("Builder stores appGroupIdentifier")
    func builderStoresAppGroupIdentifier() {
        let builder = makeMeetingRoomBuilder()
            .appGroupIdentifier("group.com.vonage.test")
        #expect(builder.currentAppGroupIdentifier == "group.com.vonage.test")
    }

    @Test("Builder stores broadcastExtensionBundleId")
    func builderStoresBroadcastExtensionBundleId() {
        let builder = makeMeetingRoomBuilder()
            .broadcastExtensionBundleId("com.vonage.broadcast")
        #expect(builder.currentBroadcastExtensionBundleId == "com.vonage.broadcast")
    }

    @Test("Builder stores publisherSettings")
    func builderStoresPublisherSettings() {
        let settings = PublisherSettings(
            username: "Alice",
            publishAudio: false,
            publishVideo: true
        )
        let builder = makeMeetingRoomBuilder()
            .publisherSettings(settings)
        #expect(builder.currentPublisherSettings == settings)
    }

    @Test("Builder stores theme")
    func builderStoresTheme() {
        var theme = MeetingRoomTheme.vonage
        theme.primary = .blue
        let builder = makeMeetingRoomBuilder()
            .theme(theme)
        #expect(builder.currentTheme != nil)
    }

    @Test("Builder defaults to nil theme")
    func builderDefaultsToNilTheme() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentTheme == nil)
    }

    @Test("Builder can set all features at once")
    func builderCanSetAllFeatures() {
        let allFeatures = Set(MeetingRoomFeature.allCases)
        let builder = makeMeetingRoomBuilder()
            .enabledFeatures(allFeatures)
        #expect(builder.currentEnabledFeatures.count == 9)
    }

    @Test("Overwriting enabled features replaces the set")
    func overwritingEnabledFeatures() {
        let builder = makeMeetingRoomBuilder()
            .enabledFeatures([.chat, .captions])
            .enabledFeatures([.reactions])
        #expect(builder.currentEnabledFeatures == [.reactions])
    }

    @Test("Builder defaults to vonage provider resolver")
    func builderDefaultsToVonageProvider() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentBackgroundEffectProviderResolver() == .vonage)
    }

    @Test("Builder stores backgroundEffectProviderResolver")
    func builderStoresBackgroundEffectProviderResolver() {
        let builder = makeMeetingRoomBuilder()
            .backgroundEffectProviderResolver { .appleVision }
        #expect(builder.currentBackgroundEffectProviderResolver() == .appleVision)
    }

    @Test("Builder defaults to fast apple vision quality resolver")
    func builderDefaultsToFastQuality() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentAppleVisionQualityResolver() == .fast)
    }

    @Test("Builder stores appleVisionQualityResolver")
    func builderStoresAppleVisionQualityResolver() {
        let builder = makeMeetingRoomBuilder()
            .appleVisionQualityResolver { .accurate }
        #expect(builder.currentAppleVisionQualityResolver() == .accurate)
    }

    @Test("Builder resolvers are re-read on every access")
    func builderResolversAreReReadOnEveryAccess() {
        // A resolver-based API is only useful if the host can change the
        // returned value over time. Verify the closure is invoked on every
        // call, not snapshotted at registration.
        var providerValue: BackgroundEffectProvider = .vonage
        let builder = makeMeetingRoomBuilder()
            .backgroundEffectProviderResolver { providerValue }

        #expect(builder.currentBackgroundEffectProviderResolver() == .vonage)

        providerValue = .appleVision
        #expect(builder.currentBackgroundEffectProviderResolver() == .appleVision)
    }

    func makeMeetingRoomBuilder(
        testBaseURL: URL = URL(string: "https://api.example.com")!,
        testRoomName: String = "test-room"
    ) -> MeetingRoomBuilder {
        MeetingRoomBuilder(baseURL: testBaseURL, roomName: testRoomName)
    }
}
