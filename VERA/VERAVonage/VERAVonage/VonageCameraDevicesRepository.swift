//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore
import VERADomain

enum VonageCameraDevice: String {
    case front = "Front"
    case back = "Back"
}

public final class VonageCameraDevicesRepository: CameraDevicesRepository {
    private let _observeAvailableDevices = CurrentValueSubject<[VERACore.CameraDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[VERACore.CameraDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    private let publisherRepository: PublisherRepository

    public init(publisherRepository: PublisherRepository) {
        self.publisherRepository = publisherRepository
    }

    public func loadCameraDevices() {
        _observeAvailableDevices.value = [
            VERACore.CameraDevice(
                id: VonageCameraDevice.front.rawValue,
                name: "Front Camera"),
            VERACore.CameraDevice(
                id: VonageCameraDevice.back.rawValue,
                name: "Back Camera"),
        ]
    }
}
