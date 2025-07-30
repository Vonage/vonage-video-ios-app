//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import VERACore

public func makeMockAudioDevicesRepository() -> MockAudioDevicesRepository {
    return MockAudioDevicesRepository()
}

public final class MockAudioDevicesRepository: AudioDevicesRepository {
    public var _observeAvailableDevices = CurrentValueSubject<[VERACore.AudioDevice], Never>([])
    public lazy var observeAvailableDevices: AnyPublisher<[VERACore.AudioDevice], Never> =
        _observeAvailableDevices.eraseToAnyPublisher()

    public var routedAudioDevices: [String] = []

    public init() {}

    public func routeTo(_ audioDeviceID: String) throws {
        routedAudioDevices.append(audioDeviceID)
    }

    public func set(_ audioDevices: [VERACore.AudioDevice]) {
        _observeAvailableDevices.value = audioDevices
    }
}
