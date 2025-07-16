//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore

func makeMockCameraDevicesRepository() -> MockCameraDevicesRepository {
    return MockCameraDevicesRepository()
}

final class MockCameraDevicesRepository: CameraDevicesRepository {
    var _observeAvailableDevices = CurrentValueSubject<[VERACore.CameraDevice], Never>([])
    lazy var observeAvailableDevices: AnyPublisher<[VERACore.CameraDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    var routedCameraDevices: [String] = []

    func routeTo(_ cameraDeviceID: String) {
        routedCameraDevices.append(cameraDeviceID)
    }

    func set(_ cameraDevices: [VERACore.CameraDevice]) {
        _observeAvailableDevices.value = cameraDevices
    }
}
