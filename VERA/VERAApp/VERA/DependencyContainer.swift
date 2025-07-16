//
//  Created by Vonage on 16/7/25.
//

import AVFoundation
import Foundation
import VERACore
import VERAOpenTok

final class DependencyContainer {
    lazy var publisherFactory: PublisherFactory = {
        OpenTokPublisherFactory()
    }()

    lazy var audioDevicesRepository: any AudioDevicesRepository = {
        let repository = AVFoundationAudioDevicesRepository(
            audioSession: AVAudioSession.sharedInstance()
        )
        repository.loadAudioDevices()
        return repository
    }()

    lazy var cameraDevicesRepository: any CameraDevicesRepository = {
        let publisher = verAPublisherRepository.getPublisher()
        let repository = OpenTokCameraDevicesRepository(publisher: publisher as! OpenTokPublisher)
        repository.loadCameraDevices()
        return repository
    }()

    lazy var verAPublisherRepository: any VERAPublisherRepository = {
        DefaultVERAPublisherRepository(publisherFactory: publisherFactory)
    }()
}
