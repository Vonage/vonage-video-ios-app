//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore

public func makeMockCameraDevicesRepository() -> MockCameraDevicesRepository {
    return MockCameraDevicesRepository()
}

public final class MockCameraDevicesRepository: CameraDevicesRepository {
    public var _observeAvailableDevices = CurrentValueSubject<[VERACore.CameraDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[VERACore.CameraDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    public var routedCameraDevices: [String] = []

    public func routeTo(_ cameraDeviceID: String) {
        routedCameraDevices.append(cameraDeviceID)
    }

    public func set(_ cameraDevices: [VERACore.CameraDevice]) {
        _observeAvailableDevices.value = cameraDevices
    }
}
