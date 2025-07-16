//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

public class WaitingRoomFactory {

    private let publisherRepository: VERAPublisherRepository
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository

    public init(
        publisherRepository: VERAPublisherRepository,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository
    ) {
        self.publisherRepository = publisherRepository
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
    }

    public func make(
        roomName: RoomName,
        onNavigateToRoom: @escaping (RoomName) -> Void
    ) -> some View {
        WaitingRoomScreen(
            viewModel: .init(
                roomName: roomName,
                publisherRepository: publisherRepository,
                audioDevicesRepository: audioDevicesRepository,
                cameraDevicesRepository: cameraDevicesRepository,
                selectAudioDeviceUseCase: .init(audioDevicesRepository: audioDevicesRepository)),
            onNavigateToRoom: onNavigateToRoom
        )
    }
}
