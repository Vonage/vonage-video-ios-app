//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERAConfiguration
import VERACore
import VERADomain
import VERAVonage
import VERAVonageCallKitPlugin

#if CHAT_ENABLED
    import VERAChat
    import VERAVonageChatPlugin
#endif

#if ARCHIVING_ENABLED
    import VERAArchiving
    import VERAVonageArchivingPlugin
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
#endif

#if CAPTIONS_ENABLED
    import VERACaptions
    import VERAVonageCaptionsPlugin
#endif

#if REACTIONS_ENABLED
    import VERAReactions
    import VERAVonageReactionsPlugin
#endif

#if SCREEN_SHARE_ENABLED
    import VERAScreenShare
    import VERAVonageScreenSharePlugin
#endif

#if SETTINGS_ENABLED
    import VERASettings
    import VERAVonageSettingsPlugin
#endif

#if AUDIOEFFECTS_ENABLED
    import VERAAudioEffects
#endif

final class DependencyContainer {
    lazy var baseURL: URL = EnvironmentConstants.baseURL

    lazy var httpClient: any HTTPClient = URLSessionHTTPClient()

    lazy var jsonDecoder = JSONDecoder()

    lazy var userDefaults = UserDefaults(suiteName: EnvironmentConstants.veraAppGroupIdentifier) ?? .standard

    lazy var publisherFactory: any PublisherFactory = VonagePublisherFactory(
        checkCameraAuthorizationStatusUseCase: DefaultCheckCameraAuthorizationStatusUseCase(),
        checkMicrophoneAuthorizationStatusUseCase: DefaultCheckMicrophoneAuthorizationStatusUseCase()
    )

    lazy var appConfig = AppConfig()

    lazy var cameraDevicesRepository: any CameraDevicesRepository = {
        let repository = VonageCameraDevicesRepository(publisherRepository: publisherRepository)
        repository.loadCameraDevices()
        return repository
    }()

    lazy var publisherRepository: any PublisherRepository = {
        DefaultPublisherRepository(publisherFactory: publisherFactory)
    }()

    lazy var cameraPreviewProviderRepository: any CameraPreviewProviderRepository = {
        DefaultCameraPreviewProviderRepository(publisherFactory: publisherFactory)
    }()

    lazy var userRepository: any UserRepository = {
        UserDefaultsUserRepository(userDefaults: userDefaults)
    }()

    lazy var landingPageFactory = LandingPageFactory()

    lazy var advancedSettingsUseCase: any PublisherAdvancedSettingsUseCase = {
        #if SETTINGS_ENABLED
            return DefaultAdvancedSettingsUseCase(publisherSettingsRepository: settingsRepository)
        #else
            return NullAdvancedSettingsUseCase()
        #endif
    }()

    lazy var noiseSuppressionStatutsDataSource: any NoiseSuppressionStatusDataSource = {
        #if AUDIOEFFECTS_ENABLED
            return DefaultNoiseSuppressionStatusDataSource()
        #else
            return NullNoiseSuppressionStatusDataSource()
        #endif
    }()

    lazy var waitingRoomFactory = WaitingRoomFactory(
        publisherRepository: publisherRepository,
        cameraPreviewProviderRepository: cameraPreviewProviderRepository,
        cameraDevicesRepository: cameraDevicesRepository,
        userRepository: userRepository,
        advancedSettingsUseCase: advancedSettingsUseCase)

    lazy var meetingRoomFactory = MeetingRoomFactory(
        baseURL: baseURL,
        appConfig: appConfig,
        currentCallParticipantsRepository: currentCallParticipantsRepository,
        sessionRepository: sessionRepository,
        publisherRepository: publisherRepository,
        roomCredentialsRepository: roomCredentialsRepository,
        captionsStatusDataSource: captionsStatusDataSource,
        noiseSuppressionStatusDataSource: noiseSuppressionStatutsDataSource)

    lazy var goodByePageFactory = GoodByePageFactory(
        joinRoomUseCase: .init(
            userRepository: userRepository,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            publisherRepository: publisherRepository,
            advancedSettingsUseCase: advancedSettingsUseCase),
        userRepository: userRepository)

    lazy var currentCallParticipantsRepository = DefaultCurrentCallParticipantsRepository()

    lazy var sessionFactory = VonageSessionFactory()

    lazy var statsCollector: any StatsCollector = {
        #if SETTINGS_ENABLED
            return NetworkStatsCollector()
        #else
            return NullStatsCollector()
        #endif
    }()

    lazy var sessionRepository: SessionRepository = {
        VonageSessionRepository(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry,
            statsCollector: statsCollector
        )
    }()

    lazy var pluginRegistry: VonagePluginRegistry = {
        let registry = VonagePluginRegistry()
        #if CHAT_ENABLED
            registry.registerPlugin(plugin: vonageChatPlugin)
        #endif
        #if ARCHIVING_ENABLED
            registry.registerPlugin(plugin: vonageArchivingPlugin)
        #endif
        #if CAPTIONS_ENABLED
            registry.registerPlugin(plugin: captionsPlugin)
        #endif
        #if REACTIONS_ENABLED
            registry.registerPlugin(plugin: vonageReactionsPlugin)
        #endif
        #if SCREEN_SHARE_ENABLED
            registry.registerPlugin(plugin: vonageScreenSharePlugin)
        #endif
        #if SETTINGS_ENABLED
            registry.registerPlugin(plugin: vonageSettingsPlugin)
        #endif
        registry.registerPlugin(plugin: callKitPlugin)
        return registry
    }()

    lazy var roomCredentialsRepository: RoomCredentialsRepository = {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder
        )
    }()

    // MARK: Chat feature

    #if CHAT_ENABLED
        lazy var vonageChatPlugin = VonageChatPlugin(repository: chatMessagesRepository)

        lazy var sendChatMessageUseCase = VonageSendChatMessageUseCase(vonageChatPlugin: vonageChatPlugin)

        lazy var chatMessagesRepository: ChatMessagesRepository = DefaultChatMessagesRepository()

        lazy var chatFactory = ChatFactory(
            chatMessagesRepository: chatMessagesRepository,
            sendChatMessageUseCase: sendChatMessageUseCase)
    #endif

    // MARK: CallKit feature

    lazy var callKitPlugin: VonageCallKitPlugin = {
        let plugin = VonageCallKitPlugin()
        plugin.setup()
        return plugin
    }()

    // MARK: Archiving feature

    #if ARCHIVING_ENABLED
        lazy var vonageArchivingPlugin = VonageArchivingPlugin(
            archivingStatusDataSource: archivingStatusDataSource)

        lazy var archivingStatusDataSource = DefaultArchivingStatusDataSource()

        lazy var archivingFactory = ArchivingFactory(
            archivesRepository: archivesRepository,
            archivingDataSource: archivingDataSource,
            archivingStatusDataSource: archivingStatusDataSource)

        lazy var archivingDataSource: ArchivingDataSource = DefaultArchivingDataSource(
            baseURL: baseURL,
            httpClient: httpClient)

        lazy var archivesRepository: ArchivesRepository = {
            DefaultArchivesRepository(archivesDataSource: archivesDataSource)
        }()

        lazy var archivesDataSource: ArchivesDataSource = HTTPArchivesDataSource(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)

    #endif

    // MARK: Background effects feature

    #if BACKGROUND_EFFECTS_ENABLED
        lazy var backgroundBlurFactory = BackgroundBlurFactory()
    #endif

    // MARK: Captions feature

    #if CAPTIONS_ENABLED
        lazy var captionsActivationDataSource: CaptionsActivationDataSource = DefaultCaptionsDataSource(
            baseURL: baseURL, httpClient: httpClient, jsonDecoder: jsonDecoder)

        lazy var captionsStatusDataSource: CaptionsStatusDataSource = DefaultCaptionsStatusDataSource()

        lazy var captionsRepository: CaptionsRepository = DefaultCaptionsRepository()

        lazy var captionsFactory = CaptionsFactory(
            captionsActivationDataSource: captionsActivationDataSource,
            captionsStatusDataSource: captionsStatusDataSource,
            captionsRepository: captionsRepository)

        lazy var captionsPlugin: VonageCaptionsPlugin = {
            let plugin = VonageCaptionsPlugin(
                captionsStatusDataSource: captionsStatusDataSource,
                captionsRepository: captionsRepository)
            return plugin
        }()
    #else
        lazy var captionsStatusDataSource: CaptionsStatusDataSource = NullCaptionsStatusDataSource()
    #endif

    // MARK: Reactions feature

    #if REACTIONS_ENABLED
        lazy var reactionsRepository: ReactionsRepository = DefaultReactionsRepository()

        lazy var vonageReactionsPlugin = VonageReactionsPlugin(repository: reactionsRepository)

        lazy var sendReactionUseCase: SendReactionUseCase = VonageSendReactionUseCase(
            plugin: vonageReactionsPlugin)

        lazy var reactionsFactory = ReactionsFactory(
            reactionsRepository: reactionsRepository,
            sendReactionUseCase: sendReactionUseCase)
    #endif

    // MARK: Screen share feature

    #if SCREEN_SHARE_ENABLED
        lazy var screenShareCredentialsRepository: ScreenShareCredentialsRepository =
            UserDefaultsScreenShareCredentialsRepository(userDefaults: userDefaults)

        lazy var vonageScreenSharePlugin = VonageScreenSharePlugin(
            credentialsRepository: screenShareCredentialsRepository)
    #endif

    // MARK: Settings feature

    #if SETTINGS_ENABLED
        lazy var settingsRepository: PublisherSettingsRepository =
            UserDefaultsSettingsRepository()

        lazy var statsRepository: StatsRepository = InMemoryStatsRepository()

        lazy var vonageSettingsPlugin = VonageSettingsPlugin(
            settingsRepository: settingsRepository,
            statsWriter: statsRepository)

        lazy var settingsFactory = SettingsFactory(
            repository: settingsRepository,
            statsDataSource: statsRepository)
    #endif

    // MARK: AudioEffects feature

    #if AUDIOEFFECTS_ENABLED
        lazy var audioEffectsFactory = AudioEffectsFactory(
            publisherRepostiory: publisherRepository,
            disableNoiseSuppresionUseCase: DefaultDisableNoiseSuppressionUseCase(
                noiseSuppressionStatusDataSource: noiseSuppressionStatutsDataSource
            ),
            enableNoiseSuppresionUseCase: DefaultEnableNoiseSuppressionUseCase(
                noiseSuppressionStatusDataSource: noiseSuppressionStatutsDataSource
            )
        )
    #endif
}
