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
import VERASettings
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

    @Test("Plugin registry includes archiving plugin when only post-call transcription is enabled")
    func pluginRegistryIncludesArchivingPluginForTranscription() {
        let container = makeContainer(enabledFeatures: [.postCallTranscription])
        let plugins = container.pluginRegistry.plugins
        #expect(plugins.contains { $0.pluginIdentifier == "VonageArchivingPlugin" })
    }

    @Test("Plugin registry excludes archiving plugin when recording and transcription are disabled")
    func pluginRegistryExcludesArchivingPluginWhenDisabled() {
        let container = makeContainer(enabledFeatures: [])
        let plugins = container.pluginRegistry.plugins
        #expect(!plugins.contains { $0.pluginIdentifier == "VonageArchivingPlugin" })
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

    @Test(
        "Captions translation needs both captions and captionsTranslation",
        arguments: [
            (Set<MeetingRoomFeature>([.captions, .captionsTranslation]), true),
            (Set<MeetingRoomFeature>([.captions]), false),
            (Set<MeetingRoomFeature>([.captionsTranslation]), false),
            (Set<MeetingRoomFeature>(), false),
        ])
    func captionsTranslationRequiresCaptions(features: Set<MeetingRoomFeature>, expected: Bool) {
        let container = makeContainer(enabledFeatures: features)

        #expect(container.isCaptionsTranslationEnabled == expected)
        #expect(container.settingsFactory.isCaptionsTranslationAvailable == expected)
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

    @Test("Archiving data source factory shares the container's status data source")
    func archivingDataSourceFactorySharesStatusDataSource() throws {
        var receivedContext: MeetingRoomArchivingDataSourceFactoryContext?
        let factory = ArchivingDataSourceFactorySpy { context in
            receivedContext = context
            return ArchivingDataSourceStub()
        }

        let container = makeContainer(
            enabledFeatures: [.postCallTranscription],
            archivingDataSourceFactory: factory)
        _ = container.archivingDataSource

        let context = try #require(receivedContext)
        #expect(context.archivingStatusDataSource as AnyObject === container.archivingStatusDataSource as AnyObject)
    }

    // MARK: - Transcription summary default

    @Test("Transcription defaults are the built-in defaults when settings are disabled")
    func transcriptionDefaultsWithoutSettings() async {
        let container = makeContainer(enabledFeatures: [.postCallTranscription])

        #expect(await container.loadTranscriptionDefaults() == .default)
    }

    @Test("Transcription defaults follow the saved AI summary setting")
    func transcriptionDefaultsFollowTheSavedSetting() async throws {
        let suiteName = "com.vonage.vera.tests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        await repository.save(PublisherSettingsPreferences(transcriptionSummaryEnabled: false))
        let container = makeContainer(enabledFeatures: [.postCallTranscription, .settings])
        container.settingsRepository = repository

        #expect(await container.loadTranscriptionDefaults() == TranscriptionOptions(hasSummary: false))
    }

    @Test(
        "Settings offer the AI summary default only with post-call transcription",
        arguments: [
            (Set<MeetingRoomFeature>([.settings, .postCallTranscription]), true),
            (Set<MeetingRoomFeature>([.settings]), false),
        ])
    @MainActor
    func settingsOfferTranscriptionSummary(features: Set<MeetingRoomFeature>, isShown: Bool) {
        let container = makeContainer(enabledFeatures: features)

        let (viewModel, _) = container.settingsFactory.makeMeetingRoomViewModels()

        #expect(viewModel.showsTranscriptionSummary == isShown)
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
    func post(_ url: URL, additionalHeaders: [String: String], data: Data) async throws -> Data {
        Data()
    }

    func get(_ url: URL, additionalHeaders: [String: String]) async throws -> Data {
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

    func createSession(for roomName: RoomName) async throws -> any CallFacade {
        let call = CallFacadeStub()
        currentCall = call
        return call
    }

    func clearSession() {
        currentCall = nil
    }
}

private final class CallFacadeStub: CallFacade {
    let publisherAudioLevelPublisher: AnyPublisher<Float, Never> = Just(0.0).eraseToAnyPublisher()

    var participantsPublisher = Just(ParticipantsState.empty).eraseToAnyPublisher()
    var eventsPublisher = Just(SessionEvent.idle).eraseToAnyPublisher()
    var statePublisher = Just(SessionState(isPublishingAudio: true, isPublishingVideo: true)).eraseToAnyPublisher()
    var callState = Just(CallState.idle).eraseToAnyPublisher()
    var archivingState = Just(ArchivingState.idle).eraseToAnyPublisher()
    var transcriptionState = Just(ArchivingState.idle).eraseToAnyPublisher()
    var captionsPublisher = Just([CaptionItem]()).eraseToAnyPublisher()
    var networkStatsPublisher = Just(NetworkMediaStats.empty).eraseToAnyPublisher()

    var isMuted = false
    var isOnHold = false
    var areCaptionsEnabled = false

    func connect() async throws {}
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
    func enableSubscriberExtraStats() {}
    func disableSubscriberExtraStats() {}
    func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws {}
    func updateLivePublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async {}
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
