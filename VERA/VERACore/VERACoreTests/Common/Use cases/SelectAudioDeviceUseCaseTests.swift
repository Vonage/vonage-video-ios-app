//
//  Created by Vonage on 16/7/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("Select audio device tests")
struct SelectAudioDeviceUseCaseTests {

    @Test func checkSelectAudioDeviceUpdatesRepositoryState() async throws {
        let audioDevicesRepository = MockAudioDevicesRepository()
        let sut = makeSUT(audioDevicesRepository: audioDevicesRepository)

        let audioDevice = AudioDevice(id: "anID", name: "a name", portDescription: "a port")
        try sut(audioDevice)

        #expect(
            audioDevicesRepository.routedAudioDevices.contains(where: { deviceID in
                audioDevice.id == deviceID
            }))
    }

    // MARK: SUT

    func makeSUT(
        audioDevicesRepository: AudioDevicesRepository = MockAudioDevicesRepository()
    ) -> SelectAudioDeviceUseCase {
        return SelectAudioDeviceUseCase(audioDevicesRepository: audioDevicesRepository)
    }
}
