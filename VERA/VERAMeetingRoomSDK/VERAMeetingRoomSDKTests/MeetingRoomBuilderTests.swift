//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERAArchiving
import VERABackgroundEffects
import VERACommonUI
import VERACore
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
            .uiProvider(DefaultMeetingRoomUIProvider())
            .appGroupIdentifier("group.com.test")
            .broadcastExtensionBundleId("com.test.broadcast")

        #expect(builder.currentBaseURL == testBaseURL)
        #expect(builder.currentRoomName == testRoomName)
        #expect(builder.currentEnabledFeatures == [.chat, .archiving])
        #expect(builder.currentUIProvider != nil)
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

    @Test("Builder defaults to nil UI provider")
    func builderDefaultsToNilUIProvider() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentUIProvider == nil)
    }

    @Test("Builder stores UI provider")
    func builderStoresUIProvider() {
        let builder = makeMeetingRoomBuilder()
            .uiProvider(DefaultMeetingRoomUIProvider())

        #expect(builder.currentUIProvider is DefaultMeetingRoomUIProvider)
    }

    @Test("Builder defaults to real dependency factories")
    func builderDefaultsToRealDependencyFactories() {
        let builder = makeMeetingRoomBuilder()
        #expect(builder.currentHTTPClientFactory is DefaultMeetingRoomHTTPClientFactory)
        #expect(builder.currentSessionRepositoryFactory is DefaultMeetingRoomSessionRepositoryFactory)
        #expect(
            builder.currentArchivingDataSourceFactory is DefaultMeetingRoomArchivingDataSourceFactory)
    }

    @Test("Builder stores custom dependency factories")
    func builderStoresCustomDependencyFactories() {
        let builder = makeMeetingRoomBuilder()
            .httpClientFactory(HTTPClientFactoryStub())
            .sessionRepositoryFactory(SessionRepositoryFactoryStub())
            .archivingDataSourceFactory(ArchivingDataSourceFactoryStub())

        #expect(builder.currentHTTPClientFactory is HTTPClientFactoryStub)
        #expect(builder.currentSessionRepositoryFactory is SessionRepositoryFactoryStub)
        #expect(builder.currentArchivingDataSourceFactory is ArchivingDataSourceFactoryStub)
    }

    @Test("Builder can set all features at once")
    func builderCanSetAllFeatures() {
        let allFeatures = Set(MeetingRoomFeature.allCases)
        let builder = makeMeetingRoomBuilder()
            .enabledFeatures(allFeatures)
        #expect(builder.currentEnabledFeatures.count == 11)
    }

    @Test("Overwriting enabled features replaces the set")
    func overwritingEnabledFeatures() {
        let builder = makeMeetingRoomBuilder()
            .enabledFeatures([.chat, .captions])
            .enabledFeatures([.reactions])
        #expect(builder.currentEnabledFeatures == [.reactions])
    }

    func makeMeetingRoomBuilder(
        testBaseURL: URL = URL(string: "https://api.example.com")!,
        testRoomName: String = "test-room"
    ) -> MeetingRoomBuilder {
        MeetingRoomBuilder(baseURL: testBaseURL, roomName: testRoomName)
    }
}

private final class HTTPClientFactoryStub: MeetingRoomHTTPClientFactory {
    func callAsFunction(_ context: HTTPClientContext) -> any HTTPClient {
        HTTPClientStub()
    }
}

private final class HTTPClientStub: HTTPClient {

    func get(_ url: URL) async throws -> Data {
        Data()
    }

    func post(_ url: URL, additionalHeaders: [String: String], data: Data) async throws -> Data {
        Data()
    }
}

private final class SessionRepositoryFactoryStub: MeetingRoomSessionRepositoryFactory {
    func callAsFunction(
        _ context: MeetingRoomSessionRepositoryFactoryContext
    ) -> any SessionRepository {
        SessionRepositoryStub()
    }
}

private final class ArchivingDataSourceFactoryStub:
    MeetingRoomArchivingDataSourceFactory
{
    func callAsFunction(
        _ context: MeetingRoomArchivingDataSourceFactoryContext
    ) -> any ArchivingDataSource {
        ArchivingDataSourceStub()
    }
}

private final class SessionRepositoryStub: SessionRepository {
    var currentCall: (any CallFacade)?

    func createSession(_ credentials: RoomCredentials) async throws -> any CallFacade {
        fatalError("Not used")
    }

    func clearSession() {}
}

private final class ArchivingDataSourceStub: ArchivingDataSource {
    func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        fatalError("Not used")
    }

    func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        fatalError("Not used")
    }
}
