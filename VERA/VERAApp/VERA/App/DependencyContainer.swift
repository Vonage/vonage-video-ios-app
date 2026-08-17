//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERACommonUI
import VERAConfiguration
import VERACore
import VERADomain
import VERAE2E
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

#if AUDIODIAGNOSTICS_ENABLED
    import VERAAudioDiagnostics
#endif

#if OKTA_ENABLED
    import VERAOKTA
#endif

final class DependencyContainer {

    private let baseHttpClient: HTTPClient

    #if OKTA_ENABLED
        lazy var authManager: any OKTAAuthenticating = {
            if E2EConfiguration.isEnabled {
                return E2EAuthStateManager()
            }
            let okta = OktaAuthManager()
            okta.restoreSession()
            return okta
        }()

        lazy var httpClient: HTTPClient = {
            if E2EConfiguration.isEnabled {
                return baseHttpClient
            }
            return TokenInjectingHTTPClient(
                wrapped: baseHttpClient,
                tokenProvider: OktaTokenProvider(authManager: authManager)
            )
        }()
    #else
        var httpClient: HTTPClient { baseHttpClient }
    #endif

    init(httpClient: HTTPClient) {
        self.baseHttpClient = httpClient
    }

    lazy var baseURL: URL = EnvironmentConstants.baseURL

    lazy var jsonDecoder = JSONDecoder()

    let sessionKeyHolder = DefaultSessionKeyHolder()

    lazy var userDefaults = UserDefaults(suiteName: EnvironmentConstants.veraAppGroupIdentifier) ?? .standard

    lazy var publisherFactory: any PublisherFactory = {
        let camera = DefaultCheckCameraAuthorizationStatusUseCase()
        let microphone = DefaultCheckMicrophoneAuthorizationStatusUseCase()
        return appConfig.meetingRoomSettings.allowPictureInPicture
            ? PictureInPictureVonagePublisherFactory(
                checkCameraAuthorizationStatusUseCase: camera,
                checkMicrophoneAuthorizationStatusUseCase: microphone)
            : VonagePublisherFactory(
                checkCameraAuthorizationStatusUseCase: camera,
                checkMicrophoneAuthorizationStatusUseCase: microphone)
    }()

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
            let adapter = PublisherAdvancedSettingsAdapter()
            adapter.onChange = { [weak self] in
                self?.cameraPreviewProviderRepository.resetPublisher()
            }
            adapter.setup(with: settingsRepository.preferencesPublisher)
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

    lazy var goodByePageFactory = GoodByePageFactory(userRepository: userRepository)

    #if AUDIODIAGNOSTICS_ENABLED
        lazy var speakerTestService: SpeakerTestService = DefaultSpeakerTestService()

        lazy var audioDiagnosticsFactory = AudioDiagnosticsFactory(speakerTestService: speakerTestService)
    #endif

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
        if appConfig.meetingRoomSettings.allowFeedback { features.insert(.feedback) }
        #if !os(macOS)
            if appConfig.meetingRoomSettings.allowPictureInPicture {
                features.insert(.pictureInPicture)
            }
        #endif
        if appConfig.meetingRoomSettings.allowScreenShare && !ProcessInfo.processInfo.isiOSAppOnMac {
            features.insert(.screenShare)
        }
        if appConfig.videoSettings.allowBackgroundEffects { features.insert(.backgroundEffects) }
        if appConfig.audioSettings.allowAdvancedNoiseSuppression { features.insert(.audioEffects) }
        if appConfig.audioSettings.allowAudioDiagnostics { features.insert(.audioDiagnostics) }
        features.insert(.callKit)
        return features
    }

    // MARK: - Archiving feature (goodbye page)

    #if ARCHIVING_ENABLED
        lazy var archivingStatusDataSource = DefaultArchivingStatusDataSource()

        lazy var archivingFactory = ArchivingFactory(
            archivesRepository: archivesRepository,
            archivingDataSource: archivingDataSource,
            archivingStatusDataSource: archivingStatusDataSource,
            sessionKeyProvider: sessionKeyHolder)

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
    #endif

    // MARK: - Settings feature (waiting room)

    #if SETTINGS_ENABLED
        lazy var settingsRepository: PublisherSettingsRepository = {
            let repository = UserDefaultsSettingsRepository()
            Task { await repository.setup() }
            return repository
        }()

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
