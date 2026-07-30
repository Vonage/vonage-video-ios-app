//
//  Created by Vonage on 16/4/26.
//

import Combine
import Foundation
import VERAArchiving
import VERAAudioDiagnostics
import VERAAudioEffects
import VERABackgroundEffects
import VERACaptions
import VERAChat
import VERACommonUI
import VERACore
import VERADomain
import VERAFeedback
import VERAMeetingRoom
import VERAReactions
import VERAScreenShare
import VERASettings
import VERAVonage
import VERAVonageArchivingPlugin
import VERAVonageCallKitPlugin
import VERAVonageCaptionsPlugin
import VERAVonageChatPlugin
import VERAVonageReactionsPlugin
import VERAVonageScreenSharePlugin
import VERAVonageSettingsPlugin

/// Internal dependency container that wires all meeting room dependencies.
///
/// Created by ``MeetingRoomBuilder`` based on the enabled features.
/// The container lazily instantiates only the dependencies required
/// by the features the consumer enabled.
final class MeetingRoomSDKContainer {

    let baseURL: URL
    let enabledFeatures: Set<MeetingRoomFeature>
    let configuration: MeetingRoomConfiguration
    let appGroupIdentifier: String?
    let broadcastExtensionBundleId: String?

    private let initialPublisherSettings: PublisherSettings?
    private let httpClientFactory: any MeetingRoomHTTPClientFactory
    private let sessionRepositoryFactory: any MeetingRoomSessionRepositoryFactory
    private let archivingDataSourceFactory: any MeetingRoomArchivingDataSourceFactory

    init(
        baseURL: URL,
        enabledFeatures: Set<MeetingRoomFeature> = Set(),
        configuration: MeetingRoomConfiguration = .init(),
        publisherSettings: PublisherSettings? = nil,
        appGroupIdentifier: String? = nil,
        broadcastExtensionBundleId: String? = nil,
        httpClientFactory: any MeetingRoomHTTPClientFactory =
            DefaultMeetingRoomHTTPClientFactory(),
        sessionRepositoryFactory: any MeetingRoomSessionRepositoryFactory =
            DefaultMeetingRoomSessionRepositoryFactory(),
        archivingDataSourceFactory: any MeetingRoomArchivingDataSourceFactory =
            DefaultMeetingRoomArchivingDataSourceFactory()
    ) {
        self.baseURL = baseURL
        self.enabledFeatures = enabledFeatures
        self.configuration = configuration
        self.initialPublisherSettings = publisherSettings
        self.appGroupIdentifier = appGroupIdentifier
        self.broadcastExtensionBundleId = broadcastExtensionBundleId
        self.httpClientFactory = httpClientFactory
        self.sessionRepositoryFactory = sessionRepositoryFactory
        self.archivingDataSourceFactory = archivingDataSourceFactory
    }

    // MARK: - Core Dependencies

    lazy var httpClient: any HTTPClient = httpClientFactory(
        HTTPClientContext(interceptor: OSLogHTTPClientInterceptor()))

    lazy var jsonDecoder = JSONDecoder()

    var sessionKeyHolder: SessionKeyHolder = DefaultSessionKeyHolder()

    lazy var publisherFactory: any PublisherFactory = {
        let camera = DefaultCheckCameraAuthorizationStatusUseCase()
        let microphone = DefaultCheckMicrophoneAuthorizationStatusUseCase()
        return configuration.allowPictureInPicture
            ? PictureInPictureVonagePublisherFactory(
                checkCameraAuthorizationStatusUseCase: camera,
                checkMicrophoneAuthorizationStatusUseCase: microphone)
            : VonagePublisherFactory(
                checkCameraAuthorizationStatusUseCase: camera,
                checkMicrophoneAuthorizationStatusUseCase: microphone)
    }()

    lazy var publisherRepository: any PublisherRepository = {
        DefaultPublisherRepository(publisherFactory: publisherFactory)
    }()

    lazy var currentCallParticipantsRepository = DefaultCurrentCallParticipantsRepository()

    lazy var pinnedParticipantsDataSource: any PinnedParticipantsDataSource =
        DefaultPinnedParticipantsDataSource()

    lazy var roomCredentialsRepository: any RoomCredentialsRepository = {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder
        )
    }()

    lazy var sessionFactory = VonageSessionFactory()

    lazy var statsCollector: any StatsCollector = {
        if enabledFeatures.contains(.settings) {
            return NetworkStatsCollector()
        }
        return NullStatsCollector()
    }()

    lazy var sessionRepository: any SessionRepository = {
        sessionRepositoryFactory(
            MeetingRoomSessionRepositoryFactoryContext(
                publisherSettings: initialPublisherSettings ?? .init(),
                sessionFactory: sessionFactory,
                publisherRepository: publisherRepository,
                pluginRegistry: pluginRegistry,
                statsCollector: statsCollector))
    }()

    lazy var advancedSettingsUseCase: any PublisherAdvancedSettingsUseCase = {
        if enabledFeatures.contains(.settings) {
            return DefaultAdvancedSettingsUseCase(publisherSettingsRepository: settingsRepository)
        }
        return NullAdvancedSettingsUseCase()
    }()

    // MARK: - Publisher helpers

    func resetPublisher() {
        guard let initialPublisherSettings = initialPublisherSettings else { return }
        try? publisherRepository.recreatePublisher(initialPublisherSettings)
    }

    // MARK: - Plugin Registry

    lazy var pluginRegistry: VonagePluginRegistry = {
        let registry = VonagePluginRegistry()
        if enabledFeatures.contains(.chat) {
            registry.registerPlugin(plugin: vonageChatPlugin)
        }
        if enabledFeatures.contains(.archiving) {
            registry.registerPlugin(plugin: vonageArchivingPlugin)
        }
        if enabledFeatures.contains(.captions) {
            registry.registerPlugin(plugin: captionsPlugin)
        }
        if enabledFeatures.contains(.reactions) {
            registry.registerPlugin(plugin: vonageReactionsPlugin)
        }
        if enabledFeatures.contains(.screenShare) {
            registry.registerPlugin(plugin: vonageScreenSharePlugin)
        }
        if enabledFeatures.contains(.settings) {
            registry.registerPlugin(plugin: vonageSettingsPlugin)
        }
        if enabledFeatures.contains(.callKit) {
            registry.registerPlugin(plugin: callKitPlugin)
        }
        return registry
    }()

    // MARK: - CallKit Plugin (always included)

    lazy var callKitPlugin: VonageCallKitPlugin = {
        let plugin = VonageCallKitPlugin()
        plugin.setup()
        return plugin
    }()

    // MARK: - Meeting Room Factory

    lazy var meetingRoomFactory = MeetingRoomFactory(
        baseURL: baseURL,
        configuration: configuration,
        currentCallParticipantsRepository: currentCallParticipantsRepository,
        sessionRepository: sessionRepository,
        publisherRepository: publisherRepository,
        roomCredentialsRepository: roomCredentialsRepository,
        captionsStatusDataSource: captionsStatusDataSource,
        noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource,
        pinnedParticipantsDataSource: pinnedParticipantsDataSource,
        sessionKeyHolder: sessionKeyHolder
    )

    // MARK: - Chat Feature

    lazy var chatMessagesRepository: any ChatMessagesRepository = DefaultChatMessagesRepository()

    lazy var vonageChatPlugin = VonageChatPlugin(repository: chatMessagesRepository)

    lazy var sendChatMessageUseCase: SendChatMessageUseCase =
        VonageSendChatMessageUseCase(vonageChatPlugin: vonageChatPlugin)

    lazy var chatBadgeButtonViewModel = ChatBadgeButtonViewModel(
        chatMessagesObserver: chatMessagesRepository)

    lazy var chatFactory = ChatFactory(
        chatMessagesRepository: chatMessagesRepository,
        sendChatMessageUseCase: sendChatMessageUseCase)

    // MARK: - Archiving Feature

    lazy var archivingStatusDataSource: any ArchivingStatusDataSource =
        DefaultArchivingStatusDataSource()

    lazy var vonageArchivingPlugin = VonageArchivingPlugin(
        archivingStatusDataSource: archivingStatusDataSource)

    lazy var archivingDataSource: any ArchivingDataSource = {
        archivingDataSourceFactory(
            MeetingRoomArchivingDataSourceFactoryContext(
                baseURL: baseURL,
                httpClient: httpClient,
                archivingStatusDataSource: archivingStatusDataSource))
    }()

    lazy var archivesDataSource: any ArchivesDataSource = HTTPArchivesDataSource(
        baseURL: baseURL,
        httpClient: httpClient,
        jsonDecoder: jsonDecoder)

    lazy var archivesRepository: any ArchivesRepository = {
        DefaultArchivesRepository(archivesDataSource: archivesDataSource)
    }()

    lazy var archivingFactory = ArchivingFactory(
        archivesRepository: archivesRepository,
        archivingDataSource: archivingDataSource,
        archivingStatusDataSource: archivingStatusDataSource,
        sessionKeyProvider: sessionKeyHolder)

    // MARK: - Background Effects Feature

    lazy var backgroundEffectsRepository: BackgroundEffectsRepository = DefaultBackgroundEffectsRepository(
        bundle: .init(for: DefaultBackgroundEffectsRepository.self),
        storageProvider: DefaultBackgroundEffectsStorageProvider(
            fileManager: .default,
            searchPathDirectory: .cachesDirectory,
            pathComponent: "video_backgrounds"
        )
    )

    lazy var userBackgroundRepository: UserBackgroundRepository = DefaultUserBackgroundRepository(
        storageProvider: DefaultBackgroundEffectsStorageProvider(
            fileManager: .default,
            searchPathDirectory: .documentDirectory,
            pathComponent: "user_backgrounds"
        )
    )

    lazy var videoEffectRepository: VideoEffectRepository = DefaultVideoEffectRepository()

    lazy var backgroundEffectFactory = BackgroundEffectFactory(
        getBackgroundsUseCase: DefaultGetBackgroundsUseCase(
            backgroundEffectsRepository: backgroundEffectsRepository,
            userBackgroundRepository: userBackgroundRepository
        ),
        addBackgroundUseCase: DefaultAddBackgroundUseCase(
            userBackgroundRepository: userBackgroundRepository
        ),
        deleteBackgroundUseCase: DefaultDeleteBackgroundUseCase(
            userBackgroundRepository: userBackgroundRepository
        ),
        remainingSlotsPublisher: userBackgroundRepository.remainingSlotsPublisher,
        videoEffectRepository: videoEffectRepository
    )

    // MARK: - Captions Feature

    lazy var captionsActivationDataSource: any CaptionsActivationDataSource =
        DefaultCaptionsDataSource(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)

    lazy var captionsStatusDataSource: any CaptionsStatusDataSource = {
        if enabledFeatures.contains(.captions) {
            return DefaultCaptionsStatusDataSource()
        }
        return NullCaptionsStatusDataSource()
    }()

    lazy var captionsRepository = DefaultCaptionsRepository()

    lazy var captionsFactory = CaptionsFactory(
        captionsActivationDataSource: captionsActivationDataSource,
        captionsStatusDataSource: captionsStatusDataSource,
        captionsRepository: captionsRepository,
        sessionKeyProvider: sessionKeyHolder)

    lazy var captionsPlugin: VonageCaptionsPlugin = {
        VonageCaptionsPlugin(
            captionsStatusDataSource: captionsStatusDataSource,
            captionsRepository: captionsRepository)
    }()

    // MARK: - Reactions Feature

    lazy var reactionsRepository: any ReactionsRepository = DefaultReactionsRepository()

    lazy var vonageReactionsPlugin = VonageReactionsPlugin(repository: reactionsRepository)

    lazy var sendReactionUseCase: any SendReactionUseCase =
        VonageSendReactionUseCase(plugin: vonageReactionsPlugin)

    lazy var reactionsFactory = ReactionsFactory(
        reactionsRepository: reactionsRepository,
        sendReactionUseCase: sendReactionUseCase)

    // MARK: - Screen Share Feature

    lazy var screenShareCredentialsRepository: any ScreenShareCredentialsRepository = {
        if let identifier = appGroupIdentifier,
            let userDefaults = UserDefaults(suiteName: identifier)
        {
            return UserDefaultsScreenShareCredentialsRepository(userDefaults: userDefaults)
        }
        return UserDefaultsScreenShareCredentialsRepository(userDefaults: .standard)
    }()

    lazy var vonageScreenSharePlugin = VonageScreenSharePlugin(
        credentialsRepository: screenShareCredentialsRepository)

    // MARK: - Settings Feature

    lazy var settingsRepository: any PublisherSettingsRepository =
        UserDefaultsSettingsRepository()

    lazy var statsRepository: any StatsRepository = InMemoryStatsRepository()

    lazy var vonageSettingsPlugin = VonageSettingsPlugin(
        settingsRepository: settingsRepository,
        statsWriter: statsRepository)

    lazy var defaultSpeakerTestService = DefaultSpeakerTestService()

    lazy var audioDiagnosticsFactory = AudioDiagnosticsFactory(
        speakerTestService: defaultSpeakerTestService
    )

    lazy var settingsFactory = SettingsFactory(
        repository: settingsRepository,
        statsDataSource: statsRepository
    )

    lazy var feedbackFactory = FeedbackFactory(
        baseURL: baseURL,
        httpClient: httpClient
    )

    // MARK: - Audio Effects Feature

    lazy var noiseSuppressionStatusDataSource: any NoiseSuppressionStatusDataSource = {
        if enabledFeatures.contains(.audioEffects) {
            return DefaultNoiseSuppressionStatusDataSource()
        }
        return NullNoiseSuppressionStatusDataSource()
    }()

    lazy var audioEffectsFactory = AudioEffectsFactory(
        publisherRepository: publisherRepository,
        disableNoiseSuppressionUseCase: DefaultDisableNoiseSuppressionUseCase(
            noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource
        ),
        enableNoiseSuppressionUseCase: DefaultEnableNoiseSuppressionUseCase(
            noiseSuppressionStatusDataSource: noiseSuppressionStatusDataSource
        )
    )

    // MARK: - Feature Check

    func isFeatureEnabled(_ feature: MeetingRoomFeature) -> Bool {
        enabledFeatures.contains(feature)
    }
}
