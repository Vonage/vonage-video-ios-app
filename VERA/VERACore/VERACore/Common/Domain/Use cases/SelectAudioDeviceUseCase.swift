//
//  Created by Vonage on 16/7/25.
//

import Foundation

public final class SelectAudioDeviceUseCase {

    private let audioDevicesRepository: AudioDevicesRepository

    public init(audioDevicesRepository: AudioDevicesRepository) {
        self.audioDevicesRepository = audioDevicesRepository
    }

    public func callAsFunction(_ audioDevice: AudioDevice) throws {
        try audioDevicesRepository.routeTo(audioDevice.id)
    }
}
