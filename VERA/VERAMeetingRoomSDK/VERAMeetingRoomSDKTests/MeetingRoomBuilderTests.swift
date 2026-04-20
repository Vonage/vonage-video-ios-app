//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomBuilder tests")
struct MeetingRoomBuilderTests {

    private let testBaseURL = URL(string: "https://api.example.com")!
    private let testRoomName = "test-room"

    @Test("Builder stores baseURL")
    func builderStoresBaseURL() {
        let builder = MeetingRoomBuilder()
            .baseURL(testBaseURL)
        #expect(builder.currentBaseURL == testBaseURL)
    }

    @Test("Builder stores roomName")
    func builderStoresRoomName() {
        let builder = MeetingRoomBuilder()
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
        let builder = MeetingRoomBuilder()
            .configuration(config)
        #expect(builder.currentConfiguration == config)
    }

    @Test("Builder stores enabled features")
    func builderStoresEnabledFeatures() {
        let features: Set<MeetingRoomFeature> = [.chat, .captions, .reactions]
        let builder = MeetingRoomBuilder()
            .enabledFeatures(features)
        #expect(builder.currentEnabledFeatures == features)
    }

    @Test("Builder defaults to empty feature set")
    func builderDefaultsToEmptyFeatures() {
        let builder = MeetingRoomBuilder()
        #expect(builder.currentEnabledFeatures.isEmpty)
    }

    @Test("Builder defaults to standard MeetingRoomConfiguration")
    func builderDefaultsToStandardConfiguration() {
        let builder = MeetingRoomBuilder()
        let defaultConfig = MeetingRoomConfiguration()
        #expect(builder.currentConfiguration == defaultConfig)
    }

    @Test("Builder supports chaining all methods")
    func builderSupportsChaining() {
        let builder = MeetingRoomBuilder()
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
        let builder = MeetingRoomBuilder()
            .appGroupIdentifier("group.com.vonage.test")
        #expect(builder.currentAppGroupIdentifier == "group.com.vonage.test")
    }

    @Test("Builder stores broadcastExtensionBundleId")
    func builderStoresBroadcastExtensionBundleId() {
        let builder = MeetingRoomBuilder()
            .broadcastExtensionBundleId("com.vonage.broadcast")
        #expect(builder.currentBroadcastExtensionBundleId == "com.vonage.broadcast")
    }

    @Test("Builder can set all features at once")
    func builderCanSetAllFeatures() {
        let allFeatures = Set(MeetingRoomFeature.allCases)
        let builder = MeetingRoomBuilder()
            .enabledFeatures(allFeatures)
        #expect(builder.currentEnabledFeatures.count == 9)
    }

    @Test("Overwriting enabled features replaces the set")
    func overwritingEnabledFeatures() {
        let builder = MeetingRoomBuilder()
            .enabledFeatures([.chat, .captions])
            .enabledFeatures([.reactions])
        #expect(builder.currentEnabledFeatures == [.reactions])
    }
}
