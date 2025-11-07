//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation
import VERAConfiguration

public typealias WaitingRoomError = String
public typealias PermissionGranted = Bool

public enum WaitingRoomViewState: Equatable {
    case loading
    case content(WaitingRoomState)
}

public final class WaitingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.default)
    @Published public var userName: String = ""
    @MainActor @Published public var error: AlertItem? = nil

    private let roomName: RoomName
    weak var publisher: VERAPublisher?

    private let cameraPreviewProviderRepository: CameraPreviewProviderRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let joinRoomUseCase: JoinRoomUseCase
    private let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    private let requestCameraPermissionUseCase: RequestCameraPermissionUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let userRepository: UserRepository

    private var availableCameraDevices: [UICameraDevice] = []

    private var initialised: Bool = false

    public init(
        roomName: RoomName,
        cameraPreviewProviderRepository: CameraPreviewProviderRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        joinRoomUseCase: JoinRoomUseCase,
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase,
        requestCameraPermissionUseCase: RequestCameraPermissionUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        userRepository: UserRepository
    ) {
        self.roomName = roomName
        self.cameraPreviewProviderRepository = cameraPreviewProviderRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.joinRoomUseCase = joinRoomUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.requestCameraPermissionUseCase = requestCameraPermissionUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.userRepository = userRepository
    }

    public func loadUI() {
        guard !initialised else { return }
        initialised = true

        observeCameraDevices()

        loadUsername()

        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: false,
            isCameraEnabled: false)

        startVideoPreviewIfNeeded()
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
            do {
                if let user = try await userRepository.get() {
                    await MainActor.run {
                        userName = user.name
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.error = AlertItem.genericError(error.localizedDescription)
                }
            }
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
                isMicrophoneEnabled: isMicrophoneEnabled,
                isCameraEnabled: isCameraEnabled,
                allowMicrophoneControl: AppConfig.audioSettings.allowMicrophoneControl,
                allowCameraControl: AppConfig.videoSettings.allowCameraControl,
                cameras: availableCameraDevices,
                publisher: publisher))
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
            self?.publisher?.switchCamera(to: device.id)
        }
        return device
    }

    private func makeBackCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "iphone.rear.camera")
        device.onTap = { [weak self] in
            self?.publisher?.switchCamera(to: device.id)
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
            Task { @MainActor [weak self] in
                self?.error = AlertItem.genericError(error.localizedDescription)
            }
        }
    }

    // MARK: Permission requests

    @MainActor
    public func checkPermissions() async {
        let micGranted = await requestMicrophonePermissionUseCase()
        guard micGranted else { return }

        let cameraGranted = await requestCameraPermissionUseCase()
        guard cameraGranted else { return }

        startVideoPreview()
    }

    @MainActor
    public func startVideoPreview() {
        let publisher = cameraPreviewProviderRepository.getPublisher()
        self.publisher = publisher

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
