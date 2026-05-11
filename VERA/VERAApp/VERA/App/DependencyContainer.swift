//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERAConfiguration
import VERACore
import VERADomain
import VERAMeetingRoom
import VERAMeetingRoomSDK
import VERAVonage
import VERAVonageCallKitPlugin

#if ARCHIVING_ENABLED
    import VERAArchiving
    import VERAVonageArchivingPlugin
#endif

#if BACKGROUND_EFFECTS_ENABLED
    import VERABackgroundEffects
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
        #if SETTINGS_ENABLED
            let adapter = publisherAdvancedSettingsAdapter
            return DefaultCameraPreviewProviderRepository(
                publisherFactory: publisherFactory,
                advancedSettingsProvider: { adapter.get() }
            )
        #else
            return DefaultCameraPreviewProviderRepository(publisherFactory: publisherFactory)
        #endif
    }()

    #if SETTINGS_ENABLED
        lazy var publisherAdvancedSettingsAdapter: PublisherAdvancedSettingsAdapter = {
            let adapter = PublisherAdvancedSettingsAdapter(repository: settingsRepository)
            adapter.onChange = { [weak self] in
                self?.cameraPreviewProviderRepository.resetPublisher()
            }
            return adapter
        }()
    #endif

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

    lazy var waitingRoomFactory = WaitingRoomFactory(
        cameraPreviewProviderRepository: cameraPreviewProviderRepository,
        cameraDevicesRepository: cameraDevicesRepository,
        userRepository: userRepository,
        advancedSettingsUseCase: advancedSettingsUseCase)

    lazy var goodByePageFactory = GoodByePageFactory(
        joinRoomUseCase: .init(
            userRepository: userRepository,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            advancedSettingsUseCase: advancedSettingsUseCase),
        userRepository: userRepository)

    // MARK: - Meeting Room SDK

    /// Computes the set of enabled meeting room features from the app configuration.
    ///
    /// Replaces compile-time `#if FEATURE_ENABLED` flags for meeting room features
    /// with runtime configuration read from ``AppConfig``.
    var meetingRoomEnabledFeatures: Set<MeetingRoomFeature> {
        var features: Set<MeetingRoomFeature> = []
        if appConfig.meetingRoomSettings.allowChat { features.insert(.chat) }
        if appConfig.meetingRoomSettings.allowArchiving { features.insert(.archiving) }
        if appConfig.meetingRoomSettings.allowCaptions { features.insert(.captions) }
        if appConfig.meetingRoomSettings.allowEmojis { features.insert(.reactions) }
        if appConfig.meetingRoomSettings.allowSettings { features.insert(.settings) }
        if appConfig.meetingRoomSettings.allowScreenShare { features.insert(.screenShare) }
        if appConfig.videoSettings.allowBackgroundEffects { features.insert(.backgroundEffects) }
        if appConfig.audioSettings.allowAdvancedNoiseSuppression { features.insert(.audioEffects) }
        features.insert(.callKit)
        return features
    }

    // MARK: - Archiving feature (goodbye page)

    #if ARCHIVING_ENABLED
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

    // MARK: - Background effects feature (waiting room)

    #if BACKGROUND_EFFECTS_ENABLED
        lazy var backgroundBlurFactory = BackgroundBlurFactory()
    #endif

    // MARK: - Settings feature (waiting room)

    #if SETTINGS_ENABLED
        lazy var settingsRepository: PublisherSettingsRepository =
            UserDefaultsSettingsRepository()

        lazy var settingsFactory = SettingsFactory(
            repository: settingsRepository,
            statsDataSource: InMemoryStatsRepository())
    #endif

    // MARK: - AudioEffects feature (waiting room)

    #if AUDIOEFFECTS_ENABLED
        lazy var defaultNoiseSuppressionStatusDataSource = DefaultNoiseSuppressionStatusDataSource()

        lazy var audioEffectsFactory = AudioEffectsFactory(
            publisherRepository: publisherRepository,
            disableNoiseSuppressionUseCase: DefaultDisableNoiseSuppressionUseCase(
                noiseSuppressionStatusDataSource: defaultNoiseSuppressionStatusDataSource
            ),
            enableNoiseSuppressionUseCase: DefaultEnableNoiseSuppressionUseCase(
                noiseSuppressionStatusDataSource: defaultNoiseSuppressionStatusDataSource
            )
        )
    #endif
}
