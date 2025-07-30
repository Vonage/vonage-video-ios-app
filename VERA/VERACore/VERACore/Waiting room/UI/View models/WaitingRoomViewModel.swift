//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation

public typealias WaitingRoomError = String
public typealias PermissionGranted = Bool

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
    weak var publisher: VERAPublisher?

    private let publisherRepository: PublisherRepository
    private let audioDevicesRepository: AudioDevicesRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let selectAudioDeviceUseCase: SelectAudioDeviceUseCase
    private let joinRoomUseCase: JoinRoomUseCase
    private let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    private let requestCameraPermissionUseCase: RequestCameraPermissionUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let userRepository: UserRepository

    private var availableAudioDevices: [UIAudioDevice] = []
    private var availableCameraDevices: [UICameraDevice] = []

    private var cancellables = Set<AnyCancellable>()

    public init(
        roomName: RoomName,
        publisherRepository: PublisherRepository,
        audioDevicesRepository: AudioDevicesRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        selectAudioDeviceUseCase: SelectAudioDeviceUseCase,
        joinRoomUseCase: JoinRoomUseCase,
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase,
        requestCameraPermissionUseCase: RequestCameraPermissionUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        userRepository: UserRepository
    ) {
        self.roomName = roomName
        self.publisherRepository = publisherRepository
        self.audioDevicesRepository = audioDevicesRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.selectAudioDeviceUseCase = selectAudioDeviceUseCase
        self.joinRoomUseCase = joinRoomUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.requestCameraPermissionUseCase = requestCameraPermissionUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.userRepository = userRepository
    }

    public func loadUI() {
        observeAudioDevices()
        observeCameraDevices()

        loadUsername()

        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: false,
            isCameraEnabled: false)
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
        }.sink(receiveValue: { [weak self] in
            self?.availableCameraDevices = $0
            self?.handleDevicesChanged()
        })
        .store(in: &cancellables)
    }

    private func loadUsername() {
        Task {
            if let user = try? await userRepository.get() {
                await MainActor.run {
                    userName = user.name
                }
            }
        }
    }

    public func selectAudioDevice(_ device: AudioDevice) {
        do {
            try selectAudioDeviceUseCase(device)
        } catch {
            print("Error selecting audio device: \(error)")
        }
    }

    public func onMicToggle() {
        guard let publisher else { return }
        publisher.publishAudio.toggle()
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publisher.publishAudio,
            isCameraEnabled: publisher.publishVideo)
    }

    public func onCameraToggle() {
        guard let publisher else { return }
        publisher.publishVideo.toggle()
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publisher.publishAudio,
            isCameraEnabled: publisher.publishVideo)
    }

    private func buildContentUiState(roomName: String, isMicrophoneEnabled: Bool, isCameraEnabled: Bool) {
        state = .content(
            .init(
                roomName: roomName,
                isMicrophoneEnabled: isMicrophoneEnabled,  // publisher.publishAudio
                isCameraEnabled: isCameraEnabled,  // publisher.publishVideo
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
            self?.selectAudioDevice(device)
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
            Task {
                await self?.cameraDevicesRepository.routeTo(device.id)
            }
        }
        return device
    }

    private func makeBackCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "iphone.rear.camera")
        device.onTap = { [weak self] in
            Task {
                await self?.cameraDevicesRepository.routeTo(device.id)
            }
        }
        return device
    }

    private func handleDevicesChanged() {
        let publishAudio = publisher?.publishAudio ?? false
        let publishVideo = publisher?.publishVideo ?? false

        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publishAudio,
            isCameraEnabled: publishVideo)
    }

    public func joinRoom() async {
        do {
            let request = JoinRoomRequest(roomName: roomName, userName: userName)
            try await joinRoomUseCase(request)
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: Permission requests

    @MainActor
    public func checkPermissions() async {
        let micGranted = await requestMicrophonePermissionUseCase()
        guard micGranted else { return }

        let cameraGranted = await requestCameraPermissionUseCase()
        guard cameraGranted else { return }

        await startVideoPreview()
    }

    @MainActor
    public func startVideoPreview() async {
        let publisher = await publisherRepository.getPublisher()
        self.publisher = publisher

        publisherVideoView = PublisherVideoView(videoView: publisher.view)
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publisher.publishAudio,
            isCameraEnabled: publisher.publishVideo)
    }

    func startVideoPreviewIfNeeded() {
        if checkCameraAuthorizationStatusUseCase() {
            Task { [weak self] in
                await self?.startVideoPreview()
            }
        }
    }
}
