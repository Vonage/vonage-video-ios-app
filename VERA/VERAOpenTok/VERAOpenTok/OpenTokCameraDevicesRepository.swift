//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore

enum OpenTokCameraDevice: String {
    case front = "Front"
    case back = "Back"
}

public final class OpenTokCameraDevicesRepository: CameraDevicesRepository {
    private let _observeAvailableDevices = CurrentValueSubject<[VERACore.CameraDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[VERACore.CameraDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    private let publisherRepository: PublisherRepository

    public init(publisherRepository: PublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    @MainActor
    public func routeTo(_ cameraDeviceID: String) async {
        let publisher = publisherRepository.getPublisher()
        switch cameraDeviceID {
        case OpenTokCameraDevice.front.rawValue:
            publisher.cameraPosition = .front
        case OpenTokCameraDevice.back.rawValue:
            publisher.cameraPosition = .back
        default:
            break
        }
    }

    public func loadCameraDevices() {
        _observeAvailableDevices.value = [
            VERACore.CameraDevice(
                id: OpenTokCameraDevice.front.rawValue,
                name: "Front Camera"),
            VERACore.CameraDevice(
                id: OpenTokCameraDevice.back.rawValue,
                name: "Back Camera"),
        ]
    }
}
