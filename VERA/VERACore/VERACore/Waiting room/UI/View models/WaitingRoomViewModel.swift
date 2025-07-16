//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation

public typealias WaitingRoomError = String

public enum WaitingRoomViewState: Equatable {
    case loading
    case error(WaitingRoomError)
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel: ObservableObject {


    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    @Published public var userName: String = ""
    @Published var publisherVideoView: PublisherVideoView = PublisherVideoView(videoView: nil)
    private let roomName: RoomName
    var publisher: VERAPublisher?

    private let publisherRepository: VERAPublisherRepository
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository

    private var availableAudioDevices: [UIAudioDevice] = []
    private var availableCameraDevices: [UICameraDevice] = []

    private var cancellables = Set<AnyCancellable>()

    public init(
        roomName: RoomName,
        publisherRepository: VERAPublisherRepository,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository
    ) {
        self.roomName = roomName
        self.publisherRepository = publisherRepository
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
    }

    public func loadUI() {
        let publisher = publisherRepository.getPublisher()
        self.publisher = publisher

        publisherVideoView = PublisherVideoView(videoView: publisher.view)
        buildContentUiState(roomName: roomName, publisher: publisher)

        observeAudioDevices()
        observeCameraDevices()
    }

    private func observeAudioDevices() {
        audioDevicesRepository.observeAvailableDevices.receive(
            on: DispatchQueue.main
        )
        .map { [weak self] audioDevices -> [UIAudioDevice] in
            guard let self else { return [] }
            return audioDevices.map {
                self.makeUIAudioDevice(device: $0)
            }
        }.sink(receiveValue: { [weak self] in
            self?.availableAudioDevices = $0
            self?.handleDevicesChanged()
        })
        .store(in: &cancellables)
    }

    private func observeCameraDevices() {
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

    public func selectAudioDevice(_ id: String) {
        do {
            try audioDevicesRepository.routeTo(id)
        } catch {
            print("Error selecting audio device: \(error)")
        }
    }

    public func onMicToggle() {
        guard var publisher else { return }
        publisher.publishAudio.toggle()
        buildContentUiState(roomName: roomName, publisher: publisher)
    }

    public func onCameraToggle() {
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

    private func makeUIAudioDevice(
        device: AudioDevice
    ) -> UIAudioDevice {
        var uiDevice = UIAudioDevice(
            id: device.id,
            name: device.name,
            iconName: device.portDescription)
        uiDevice.onTap = { [weak self] in
            self?.selectAudioDevice(device.id)
        }
        return uiDevice
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
