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

    private let createPublisherUseCase: GetPublisherUseCase
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository

    private var availableAudioDevices: [UIAudioDevice] = []
    private var availableCameraDevices: [UICameraDevice] = []

    private var cancellables = Set<AnyCancellable>()

    init(
        roomName: RoomName,
        createPublisherUseCase: GetPublisherUseCase,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository
    ) {
        self.roomName = roomName
        self.createPublisherUseCase = createPublisherUseCase
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
    }

    func loadUI() {
        let publisher = createPublisherUseCase.invoke()
        self.publisher = publisher

        publisherVideoView = PublisherVideoView(videoView: publisher.view)
        buildContentUiState(roomName: roomName, publisher: publisher)

        observeAudioDevices()
        observeCameraDevices()
    }

    func observeAudioDevices() {
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
            self?.availableAudioDevices = $0
            self?.handleDevicesChanged()
        })
        .store(in: &cancellables)
    }

    func observeCameraDevices() {
        cameraDevicesRepository.observeAvailableDevices.receive(
            on: DispatchQueue.main
        )
        .map { [weak self] cameraDevices -> [UICameraDevice] in
            guard let self else { return [] }
            return cameraDevices.map {
                self.makeUICameraDevice(device: $0)
            }
        }.sink(receiveValue: { [weak self] cameraDevices in
            self?.availableCameraDevices = cameraDevices
            self?.handleDevicesChanged()
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
                cameras: availableCameraDevices))
    }

    private func makeUICameraDevice(
        device: CameraDevice
    ) -> UICameraDevice {
        if device.id == "Front" {
            return makeFrontCamera(device)
        } else {
            return makeBackCamera(device)
        }
    }

    private func makeFrontCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "person.fill.viewfinder")
        device.onTap = { [weak self] in
            self?.cameraDevicesRepository.routeTo(device.id)
        }
        return device
    }

    private func makeBackCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "iphone.rear.camera")
        device.onTap = { [weak self] in
            self?.cameraDevicesRepository.routeTo(device.id)
        }
        return device
    }

    private func handleDevicesChanged() {
        guard let publisher = publisher else { return }
        buildContentUiState(roomName: roomName, publisher: publisher)
    }
}
