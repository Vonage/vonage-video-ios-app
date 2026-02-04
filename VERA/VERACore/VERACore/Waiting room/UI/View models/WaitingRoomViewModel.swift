//
//  Created by Vonage on 15/7/25.
//

import Combine
import Foundation
import VERAConfiguration
import VERADomain

public typealias WaitingRoomError = String
public typealias PermissionGranted = Bool

public enum WaitingRoomViewState: Equatable {
    case loading
    case content(WaitingRoomState)
}

@MainActor
public final class WaitingRoomViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    public enum Error: LocalizedError {
        case invalidUserName

        public var errorDescription: String? {
            switch self {
            case .invalidUserName:
                return "Invalid User Name"
            }
        }
    }

    @Published public var state: WaitingRoomViewState = .content(WaitingRoomState.initial)
    @Published public var userName: String = ""
    @Published public var extraTrailingButtons: [ViewHolder] = []

    public let roomName: RoomName
    weak var publisher: VERAPublisher?

    private let cameraPreviewProviderRepository: CameraPreviewProviderRepository
    private let cameraDevicesRepository: CameraDevicesRepository
    private let joinRoomUseCase: JoinRoomUseCase
    private let requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase
    private let requestCameraPermissionUseCase: RequestCameraPermissionUseCase
    private let checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase
    private let checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase
    private let userRepository: UserRepository
    private let waitingRoomNavigation: WaitingRoomDestination

    private var availableCameraDevices: [UICameraDevice] = []

    private var initialised: Bool = false

    private var isMicrophoneEnabled: Bool {
        checkMicrophoneAuthorizationStatusUseCase().isAuthorized && publisher?.publishAudio ?? false
    }

    private var isCameraEnable: Bool {
        checkCameraAuthorizationStatusUseCase().isAuthorized && publisher?.publishVideo ?? false
    }

    public init(
        roomName: RoomName,
        cameraPreviewProviderRepository: CameraPreviewProviderRepository,
        cameraDevicesRepository: CameraDevicesRepository,
        joinRoomUseCase: JoinRoomUseCase,
        requestMicrophonePermissionUseCase: RequestMicrophonePermissionUseCase,
        requestCameraPermissionUseCase: RequestCameraPermissionUseCase,
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase,
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase,
        userRepository: UserRepository,
        waitingRoomNavigation: WaitingRoomDestination
    ) {
        self.roomName = roomName
        self.cameraPreviewProviderRepository = cameraPreviewProviderRepository
        self.cameraDevicesRepository = cameraDevicesRepository
        self.joinRoomUseCase = joinRoomUseCase
        self.requestMicrophonePermissionUseCase = requestMicrophonePermissionUseCase
        self.requestCameraPermissionUseCase = requestCameraPermissionUseCase
        self.checkCameraAuthorizationStatusUseCase = checkCameraAuthorizationStatusUseCase
        self.checkMicrophoneAuthorizationStatusUseCase = checkMicrophoneAuthorizationStatusUseCase
        self.userRepository = userRepository
        self.waitingRoomNavigation = waitingRoomNavigation
    }

    public func loadUI() {
        guard !initialised else { return }
        initialised = true

        observeCameraDevices()

        loadUsername()

        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: false,
            isCameraEnabled: false
        )

        Task {
            await checkPermissions()
        }
    }

    public func onToggleMic() {
        if !onMicrophoneRequestPermission() {
            return
        }
        guard let publisher else { return }
        publisher.publishAudio.toggle()
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publisher.publishAudio,
            isCameraEnabled: publisher.publishVideo)
    }

    public func onToggleCamera() {
        if !onCameraRequestPermission() {
            return
        }
        guard let publisher else { return }
        publisher.publishVideo.toggle()
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: publisher.publishAudio,
            isCameraEnabled: publisher.publishVideo)
    }

    public func joinRoom() async {
        do {
            guard userName.isValidUsername else {
                throw Error.invalidUserName
            }

            let request = JoinRoomRequest(roomName: roomName, userName: userName)
            try await joinRoomUseCase(request)
            await MainActor.run {
                waitingRoomNavigation.goToMeetingRoom()
            }
        } catch {
            await MainActor.run { [weak self] in
                self?.waitingRoomNavigation.presentAlertError(with: error.localizedDescription)
            }
        }
    }
}

extension WaitingRoomViewModel {

    fileprivate func observeCameraDevices() {
        cameraDevicesRepository.observeAvailableDevices.receive(
            on: DispatchQueue.main
        )
        .map { [weak self] cameraDevices -> [UICameraDevice] in
            guard let self else { return [] }
            return cameraDevices.map {
                self.makeUICameraDevice(device: $0)
            }
        }
        .sink { [weak self] in
            self?.availableCameraDevices = $0
            self?.updateUIState()
        }
        .store(in: &cancellables)
    }

    fileprivate func loadUsername() {
        Task {
            do {
                if let user = try await userRepository.get() {
                    await MainActor.run {
                        userName = user.name
                    }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.waitingRoomNavigation.presentAlertError(with: error.localizedDescription)
                }
            }
        }
    }

    fileprivate func buildContentUiState(roomName: String, isMicrophoneEnabled: Bool, isCameraEnabled: Bool) {
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

    fileprivate func makeUICameraDevice(
        device: CameraDevice
    ) -> UICameraDevice {
        if device.id == "Front" {
            return makeFrontCamera(device)
        } else {
            return makeBackCamera(device)
        }
    }

    fileprivate func makeFrontCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "person.fill.viewfinder")
        device.onTap = { [weak self] in
            self?.publisher?.switchCamera(to: device.id)
        }
        return device
    }

    fileprivate func makeBackCamera(_ device: CameraDevice) -> UICameraDevice {
        var device = UICameraDevice(
            id: device.id,
            name: device.name,
            iconName: "iphone.rear.camera")
        device.onTap = { [weak self] in
            self?.publisher?.switchCamera(to: device.id)
        }
        return device
    }

    fileprivate func updateUIState() {
        buildContentUiState(
            roomName: roomName,
            isMicrophoneEnabled: isMicrophoneEnabled,
            isCameraEnabled: isCameraEnable)
    }

    @MainActor
    fileprivate func startVideoPreview() {
        do {
            let publisher = try cameraPreviewProviderRepository.getPublisher()
            self.publisher = publisher

            updateUIState()

        } catch {
            self.waitingRoomNavigation.presentAlertError(with: error.localizedDescription)
        }
    }

    // MARK: Permission requests

    fileprivate func onCameraRequestPermission() -> Bool {
        let permissionStatus = checkCameraAuthorizationStatusUseCase()
        if permissionStatus.isDenied {
            waitingRoomNavigation.presentCameraPermissionAlert()
        }
        return permissionStatus.isAuthorized
    }

    fileprivate func onMicrophoneRequestPermission() -> Bool {
        let permissionStatus = checkMicrophoneAuthorizationStatusUseCase()
        if permissionStatus.isDenied {
            waitingRoomNavigation.presentMicrophonePermissionAlert()
        }
        return permissionStatus.isAuthorized
    }

    @MainActor
    fileprivate func checkPermissions() async {
        _ = await requestPermission(
            permissionChecker: checkMicrophoneAuthorizationStatusUseCase,
            permissionRequester: requestMicrophonePermissionUseCase)

        _ = await requestPermission(
            permissionChecker: checkCameraAuthorizationStatusUseCase,
            permissionRequester: requestCameraPermissionUseCase)

        startVideoPreview()
    }
}
