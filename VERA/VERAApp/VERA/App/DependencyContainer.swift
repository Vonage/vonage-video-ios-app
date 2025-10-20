//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERAChat
import VERACore
import VERAOpenTok
import VERAOpenTokChatPlugin

final class DependencyContainer {
    let baseURL = URL(string: "https://meet.vonagenetworks.net/")!

    lazy var httpClient: any HTTPClient = URLSessionHTTPClient()

    lazy var jsonDecoder = JSONDecoder()

    lazy var publisherFactory: any PublisherFactory = OpenTokPublisherFactory()

    lazy var audioDevicesRepository: any AudioDevicesRepository = {
        let repository = AVFoundationAudioDevicesRepository(
            audioSession: AVAudioSession.sharedInstance()
        )
        repository.loadAudioDevices()
        return repository
    }()

    lazy var cameraDevicesRepository: any CameraDevicesRepository = {
        let repository = OpenTokCameraDevicesRepository(publisherRepository: publisherRepository)
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
        UserDefaultsUserRepository(userDefaults: .standard)
    }()

    lazy var landingPageFactory = LandingPageFactory()

    lazy var waitingRoomFactory = WaitingRoomFactory(
        publisherRepository: publisherRepository,
        cameraPreviewProviderRepository: cameraPreviewProviderRepository,
        audioDevicesRepository: audioDevicesRepository,
        cameraDevicesRepository: cameraDevicesRepository,
        userRepository: userRepository)

    lazy var meetingRoomFactory = MeetingRoomFactory(
        baseURL: baseURL,
        currentCallParticipantsRepository: currentCallParticipantsRepository,
        sessionRepository: sessionRepository,
        publisherRepository: publisherRepository,
        roomCredentialsRepository: roomCredentialsRepository)

    lazy var goodByePageFactory = GoodByePageFactory(
        joinRoomUseCase: .init(
            userRepository: userRepository,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            publisherRepository: publisherRepository),
        userRepository: userRepository,
        archivesRepository: archivesRepository,
        archiveRecordingsRepository: archiveRecordingsRepository)

    lazy var chatFactory = ChatFactory(
        chatMessagesRepository: chatMessagesRepository,
        sendChatMessageUseCase: sendChatMessageUseCase)

    lazy var currentCallParticipantsRepository = DefaultCurrentCallParticipantsRepository()

    lazy var sessionFactory = OpenTokSessionFactory()

    lazy var sessionRepository: SessionRepository = {
        OpenTokSessionRepository(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository,
            pluginRegistry: pluginRegistry)
    }()

    lazy var pluginRegistry: OpenTokPluginRegistry = {
        let registry = OpenTokPluginRegistry()
        registry.registerPlugin(plugin: openTokChatPlugin)
        return registry
    }()

    lazy var openTokChatPlugin = OpenTokChatPlugin(repository: chatMessagesRepository)

    lazy var sendChatMessageUseCase = OpenTokSendChatMessageUseCase(openTokChatPlugin: openTokChatPlugin)

    lazy var chatMessagesRepository: ChatMessagesRepository = DefaultChatMessagesRepository()

    lazy var roomCredentialsRepository: RoomCredentialsRepository = {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder
        )
    }()

    lazy var archivesRepository: ArchivesRepository = {
        DefaultArchivesRepository(archivesDataSource: archivesDataSource)
    }()

    lazy var archivesDataSource: ArchivesDataSource = HTTPArchivesDataSource(
        baseURL: baseURL,
        httpClient: httpClient,
        jsonDecoder: jsonDecoder)

    lazy var archiveRecordingsRepository: ArchiveRecordingsRepository = DefaultArchiveRecordingsRepository(
        httpClient: httpClient)
}
