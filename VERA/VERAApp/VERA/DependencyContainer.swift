//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERACore
import VERAOpenTok

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

    lazy var userRepository: any UserRepository = {
        UserDefaultsUserRepository(userDefaults: .standard)
    }()

    lazy var roomCredentialsDataSource: DefaultRoomCredentialsDataSource = {
        DefaultRoomCredentialsDataSource(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder
        )
    }()

    lazy var waitingRoomFactory = WaitingRoomFactory(
        publisherRepository: publisherRepository,
        audioDevicesRepository: audioDevicesRepository,
        cameraDevicesRepository: cameraDevicesRepository,
        userRepository: userRepository)
}
