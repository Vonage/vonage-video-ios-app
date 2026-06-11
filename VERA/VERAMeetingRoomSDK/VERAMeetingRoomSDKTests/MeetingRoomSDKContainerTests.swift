//
//  Created by Vonage on 16/4/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERACore
import VERADomain
import VERAMeetingRoom
import VERAVonage

@testable import VERAMeetingRoomSDK

@Suite("MeetingRoomSDKContainer tests")
struct MeetingRoomSDKContainerTests {

    private static let testBaseURL = URL(string: "https://api.example.com")!

    @Test("Container correctly reports feature enabled status")
    func featureEnabledStatus() {
        let container = makeContainer(enabledFeatures: [.chat, .captions])
        #expect(container.isFeatureEnabled(.chat))
        #expect(container.isFeatureEnabled(.captions))
        #expect(!container.isFeatureEnabled(.archiving))
        #expect(!container.isFeatureEnabled(.reactions))
        #expect(!container.isFeatureEnabled(.settings))
        #expect(!container.isFeatureEnabled(.screenShare))
        #expect(!container.isFeatureEnabled(.backgroundEffects))
        #expect(!container.isFeatureEnabled(.audioEffects))
    }

    @Test("Container with no features still creates core dependencies")
    func containerWithNoFeatures() {
        let container = makeContainer(enabledFeatures: [])
        #expect(container.baseURL == Self.testBaseURL)
        #expect(!container.isFeatureEnabled(.chat))
    }

    @Test("Container uses null captions data source when captions disabled")
    func nullCaptionsWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let dataSource = container.captionsStatusDataSource
        #expect(dataSource is NullCaptionsStatusDataSource)
    }

    @Test("Container uses real captions data source when captions enabled")
    func realCaptionsWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.captions])
        let dataSource = container.captionsStatusDataSource
        #expect(!(dataSource is NullCaptionsStatusDataSource))
    }

    @Test("Container uses null noise suppression data source when audio effects disabled")
    func nullNoiseSuppressionWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let dataSource = container.noiseSuppressionStatusDataSource
        #expect(dataSource is NullNoiseSuppressionStatusDataSource)
    }

    @Test("Container uses real noise suppression data source when audio effects enabled")
    func realNoiseSuppressionWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.audioEffects])
        let dataSource = container.noiseSuppressionStatusDataSource
        #expect(!(dataSource is NullNoiseSuppressionStatusDataSource))
    }

    @Test("Plugin registry includes CallKit plugin when enabled")
    func pluginRegistryIncludesCallKitWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.callKit])
        let plugins = container.pluginRegistry.plugins
        #expect(plugins.contains { $0.pluginIdentifier == "VonageCallKitPlugin" })
    }

    @Test("Plugin registry includes chat plugin when enabled")
    func pluginRegistryIncludesChatWhenEnabled() {
        let container = makeContainer(enabledFeatures: [.chat])
        let plugins = container.pluginRegistry.plugins
        #expect(plugins.contains { $0.pluginIdentifier == "VonageChatPlugin" })
    }

    @Test("Plugin registry excludes chat plugin when disabled")
    func pluginRegistryExcludesChatWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let plugins = container.pluginRegistry.plugins
        #expect(!plugins.contains { $0.pluginIdentifier == "VonageChatPlugin" })
    }

    @Test("Plugin registry has no duplicates")
    func pluginRegistryNoDuplicates() {
        let container = makeContainer(enabledFeatures: Set(MeetingRoomFeature.allCases))
        let plugins = container.pluginRegistry.plugins
        let identifiers = plugins.map(\.pluginIdentifier)
        let uniqueIdentifiers = Set(identifiers)
        #expect(identifiers.count == uniqueIdentifiers.count)
    }

    @Test("Container stores enabled features")
    func containerStoresEnabledFeatures() {
        let features: Set<MeetingRoomFeature> = [.chat, .archiving, .settings]
        let container = makeContainer(enabledFeatures: features)
        #expect(container.enabledFeatures == features)
    }

    @Test("Container stores configuration")
    func containerStoresConfiguration() {
        let config = MeetingRoomConfiguration(
            allowMicrophoneControl: false,
            allowCameraControl: true,
            showParticipantList: false
        )
        let container = MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: [],
            configuration: config,
            appGroupIdentifier: nil,
            broadcastExtensionBundleId: nil
        )
        #expect(container.configuration == config)
    }

    @Test("Container uses injected HTTP client factory")
    func containerUsesInjectedHTTPClientFactory() {
        var didReceiveInterceptor = false
        let factory = HTTPClientFactorySpy { context in
            didReceiveInterceptor = context.interceptor is OSLogHTTPClientInterceptor
            return HTTPClientStub()
        }

        let container = makeContainer(
            enabledFeatures: [],
            httpClientFactory: factory)

        #expect(container.httpClient is HTTPClientStub)
        #expect(didReceiveInterceptor)
    }

    @Test("Container uses injected session repository factory")
    func containerUsesInjectedSessionRepositoryFactory() {
        var didReceivePublisherSettings = false
        var didReceivePluginRegistry = false
        let factory = SessionRepositoryFactorySpy { context in
            didReceivePublisherSettings = context.publisherSettings == .init()
            didReceivePluginRegistry = !context.pluginRegistry.plugins.isEmpty
            return SessionRepositoryStub()
        }

        let container = makeContainer(
            enabledFeatures: [.chat],
            sessionRepositoryFactory: factory)

        #expect(container.sessionRepository is SessionRepositoryStub)
        #expect(didReceivePublisherSettings)
        #expect(didReceivePluginRegistry)
    }

    @Test("Container uses injected archiving data source factory")
    func containerUsesInjectedArchivingDataSourceFactory() {
        var didReceiveArchivingStatusDataSource = false
        let factory = ArchivingDataSourceFactorySpy { context in
            didReceiveArchivingStatusDataSource =
                context.archivingStatusDataSource is DefaultArchivingStatusDataSource
            return ArchivingDataSourceStub()
        }

        let container = makeContainer(
            enabledFeatures: [.archiving],
            archivingDataSourceFactory: factory)

        #expect(container.archivingDataSource is ArchivingDataSourceStub)
        #expect(didReceiveArchivingStatusDataSource)
    }

    // MARK: - Helpers

    private func makeContainer(
        enabledFeatures: Set<MeetingRoomFeature>,
        httpClientFactory: any MeetingRoomHTTPClientFactory =
            DefaultMeetingRoomHTTPClientFactory(),
        sessionRepositoryFactory: any MeetingRoomSessionRepositoryFactory =
            DefaultMeetingRoomSessionRepositoryFactory(),
        archivingDataSourceFactory: any MeetingRoomArchivingDataSourceFactory =
            DefaultMeetingRoomArchivingDataSourceFactory()
    ) -> MeetingRoomSDKContainer {
        MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: enabledFeatures,
            configuration: MeetingRoomConfiguration(),
            appGroupIdentifier: nil,
            broadcastExtensionBundleId: nil,
            httpClientFactory: httpClientFactory,
            sessionRepositoryFactory: sessionRepositoryFactory,
            archivingDataSourceFactory: archivingDataSourceFactory
        )
    }
}

private final class HTTPClientStub: HTTPClient {
    func get(_ url: URL) async throws -> Data {
        Data()
    }

    func post(_ url: URL, data: Data) async throws -> Data {
        Data()
    }
}

private final class HTTPClientFactorySpy: MeetingRoomHTTPClientFactory {
    private let client: (HTTPClientContext) -> any HTTPClient

    init(client: @escaping (HTTPClientContext) -> any HTTPClient) {
        self.client = client
    }

    func callAsFunction(_ context: HTTPClientContext) -> any HTTPClient {
        client(context)
    }
}

private final class SessionRepositoryFactorySpy: MeetingRoomSessionRepositoryFactory {
    private let repository: (MeetingRoomSessionRepositoryFactoryContext) -> any SessionRepository

    init(
        repository:
            @escaping (
                MeetingRoomSessionRepositoryFactoryContext
            ) -> any SessionRepository
    ) {
        self.repository = repository
    }

    func callAsFunction(
        _ context: MeetingRoomSessionRepositoryFactoryContext
    ) -> any SessionRepository {
        repository(context)
    }
}

private final class ArchivingDataSourceFactorySpy:
    MeetingRoomArchivingDataSourceFactory
{
    private let dataSource:
        (
            MeetingRoomArchivingDataSourceFactoryContext
        ) -> any ArchivingDataSource

    init(
        dataSource:
            @escaping (
                MeetingRoomArchivingDataSourceFactoryContext
            ) -> any ArchivingDataSource
    ) {
        self.dataSource = dataSource
    }

    func callAsFunction(
        _ context: MeetingRoomArchivingDataSourceFactoryContext
    ) -> any ArchivingDataSource {
        dataSource(context)
    }
}

private final class SessionRepositoryStub: SessionRepository {
    var currentCall: (any CallFacade)?

    func createSession(_ credentials: RoomCredentials) async throws -> any CallFacade {
        let call = CallFacadeStub()
        currentCall = call
        return call
    }

    func clearSession() {
        currentCall = nil
    }
}

private final class CallFacadeStub: CallFacade {
    var participantsPublisher = Just(ParticipantsState.empty).eraseToAnyPublisher()
    var eventsPublisher = Just(SessionEvent.idle).eraseToAnyPublisher()
    var statePublisher = Just(SessionState(isPublishingAudio: true, isPublishingVideo: true)).eraseToAnyPublisher()
    var callState = Just(CallState.idle).eraseToAnyPublisher()
    var archivingState = Just(ArchivingState.idle).eraseToAnyPublisher()
    var captionsPublisher = Just([CaptionItem]()).eraseToAnyPublisher()
    var networkStatsPublisher = Just(NetworkMediaStats.empty).eraseToAnyPublisher()

    var isMuted = false
    var isOnHold = false
    var areCaptionsEnabled = false

    func connect() {}
    func disconnect() async throws {}
    func toggleLocalVideo() {}
    func toggleLocalCamera() {}
    func toggleLocalAudio() {}
    func muteLocalMedia(_ isMuted: Bool) {
        self.isMuted = isMuted
    }
    func setOnHold(_ isOnHold: Bool) {
        self.isOnHold = isOnHold
    }
    func enableCaptions() async {
        areCaptionsEnabled = true
    }
    func disableCaptions() async {
        areCaptionsEnabled = false
    }
    func enableNetworkStats() {}
    func disableNetworkStats() {}
    func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws {}
}

private final class ArchivingDataSourceStub: ArchivingDataSource {
    func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        StartArchivingDataSourceResponse(archiveId: "archive-id")
    }

    func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        StopArchivingDataSourceResponse(archiveId: request.archiveID)
    }
}
