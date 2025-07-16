//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation

public typealias WaitingRoomError = String

public enum WaitingRoomViewState: Equatable {
    case loading
    case error(WaitingRoomError)
    case success(RoomName)
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel: ObservableObject {


    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    @Published public var userName: String = ""
    @Published var publisherVideoView: PublisherVideoView = PublisherVideoView(videoView: nil)
    private let roomName: RoomName
    var publisher: VERAPublisher?

    private let createPublisherUseCase: CreatePublisherUseCase
    private let audioDevicesRepository: AudioDevicesRepository
    private var availableAudioDevices: [UIAudioDevice] = []

    private var cancellables = Set<AnyCancellable>()

    init(
        roomName: RoomName,
        createPublisherUseCase: CreatePublisherUseCase,
        audioDevicesRepository: AudioDevicesRepository
    ) {
        self.roomName = roomName
        self.createPublisherUseCase = createPublisherUseCase
        self.audioDevicesRepository = audioDevicesRepository
    }

    func loadUI() {
        do {
            publisher = try createPublisherUseCase.invoke()
            if let publisher = publisher {
                publisherVideoView = PublisherVideoView(videoView: publisher.view)

                buildContentUiState(roomName: roomName, publisher: publisher)
            }
        } catch {
            print("Error: \(error)")
        }

        audioDevicesRepository.observeAvailableDevices.receive(
            on: DispatchQueue.main
        )
        .map {
            $0.map { audioDevice in
                var uiDevice = UIAudioDevice(
                    id: audioDevice.id,
                    name: audioDevice.name,
                    iconName: audioDevice.portDescription)
                uiDevice.onTap = { [weak self] in
                    self?.selectAudioDevice(audioDevice.id)
                }
                return uiDevice
            }
        }.sink(receiveValue: { [weak self] in
            guard let self else { return }
            self.handleAudioDevicesChanged($0)
        })
        .store(in: &cancellables)
    }

    func selectAudioDevice(_ id: String) {
        do {
            try audioDevicesRepository.routeTo(id)
        } catch {
            print("Error selecting audio device: \(error)")
        }
    }

    func onMicToggle() {
        guard var publisher else { return }
        publisher.publishAudio.toggle()
        buildContentUiState(roomName: roomName, publisher: publisher)
    }

    func onCameraToggle() {
        guard var publisher else { return }
        publisher.publishVideo.toggle()
        buildContentUiState(roomName: roomName, publisher: publisher)
    }

    private func buildContentUiState(roomName: String, publisher: VERAPublisher) {
        state = .content(
            .init(
                roomName: roomName,
                isMicrophoneEnabled: publisher.publishAudio,
                isCameraEnabled: publisher.publishVideo,
                audioDevices: availableAudioDevices,
                cameras: [
                    .init(id: "front", name: "Front"),
                    .init(id: "back", name: "Back"),
                ]))
    }

    private func handleAudioDevicesChanged(_ newDevices: [UIAudioDevice]) {
        availableAudioDevices = newDevices

        if let publisher = publisher {
            buildContentUiState(roomName: roomName, publisher: publisher)
        }
    }
}
