//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore

func makeMockAudioDevicesRepository() -> MockAudioDevicesRepository {
    return MockAudioDevicesRepository()
}

final class MockAudioDevicesRepository: AudioDevicesRepository {
    var _observeAvailableDevices = CurrentValueSubject<[VERACore.AudioDevice], Never>([])
    lazy var observeAvailableDevices: AnyPublisher<[VERACore.AudioDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    var routedAudioDevices: [String] = []

    func routeTo(_ audioDeviceID: String) throws {
        routedAudioDevices.append(audioDeviceID)
    }

    func set(_ audioDevices: [VERACore.AudioDevice]) {
        _observeAvailableDevices.value = audioDevices
    }
}
