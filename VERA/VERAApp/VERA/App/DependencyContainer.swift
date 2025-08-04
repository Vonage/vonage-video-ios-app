//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERACore
import VERAOpenTok

final class DependencyContainer {
    let baseURL = URL(string: "https://video.vonage.com/")!

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

    lazy var userRepository: any UserRepository = {
        UserDefaultsUserRepository(userDefaults: .standard)
    }()

    lazy var landingPageFactory = LandingPageFactory()

    lazy var waitingRoomFactory = WaitingRoomFactory(
        publisherRepository: publisherRepository,
        audioDevicesRepository: audioDevicesRepository,
        cameraDevicesRepository: cameraDevicesRepository,
        userRepository: userRepository)

    lazy var meetingRoomFactory = MeetingRoomFactory(
        currentCallParticipantsRepository: currentCallParticipantsRepository,
        sessionRepository: sessionRepository,
        publisherRepository: publisherRepository,
        roomCredentialsRepository: roomCredentialsRepository)

    lazy var goodByePageFactory = GoodByePageFactory(
        joinRoomUseCase: .init(
            userRepository: userRepository,
            publisherRepository: publisherRepository),
        userRepository: userRepository,
        archivesRepository: archivesRepository)

    lazy var currentCallParticipantsRepository = DefaultCurrentCallParticipantsRepository()

    lazy var sessionFactory = OpenTokSessionFactory()

    lazy var sessionRepository: SessionRepository = {
        OpenTokSessionRepository(
            sessionFactory: sessionFactory,
            publisherRepository: publisherRepository)
    }()

    lazy var roomCredentialsRepository: RoomCredentialsRepository = {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder
        )
    }()

    lazy var archivesRepository: ArchivesRepository = {
        DefaultArchivesRepository()
    }()
}
