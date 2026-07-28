//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERACommonUI
import VERADomain
import VERATestHelpers

@testable import VERACore

@MainActor
@Suite("Waiting room view model tests")
struct WaitingRoomViewModelTests {

    // MARK: - Initial State Tests

    @Test("Given initial state, when view model is created, then state should be the default one")
    func initialStateShouldBeDefaultContent() {
        let sut = makeSUT()

        #expect(sut.state == .content(WaitingRoomState.initial))
    }

    @Test("Given initial room name, the content state should have the same room name")
    func loadUIShouldHaveSameRoomName() async {
        let expectedRoomName = "Another room"
        let sut = makeSUT(roomName: expectedRoomName)

        sut.loadUI()

        switch sut.state {
        case .content(let state):
            #expect(state.roomName == expectedRoomName)
        default:
            Issue.record("Expected content with expected devices")
        }
    }

    @Test(
        "Given initial state, when view model is loaded, if no devices are injected then no devices are going to be available"
    )
    func loadUIShouldNotLoadAvailableDevices() {
        let sut = makeSUT()

        #expect(sut.state == .content(WaitingRoomState.initial))

        sut.loadUI()

        switch sut.state {
        case .content(let state):
            #expect(state.cameras == [])
        default:
            Issue.record("Expected content with expected devices")
        }
    }

    @Test("Given view model is loaded, when publisher is created, then onPublisherReady is called")
    func loadUIShouldCallOnPublisherReady() async {
        let sut = makeSUT()
        var publisherReadyCalled = false
        sut.onPublisherReady = {
            publisherReadyCalled = true
        }

        sut.loadUI()
        await delay()

        #expect(publisherReadyCalled)
    }

    @Test("Given publisher is reset, when new publisher is created, then onPublisherReady is called again")
    func onPublisherReadyCalledAfterReset() async {
        let repo = makeMockCameraPreviewProviderRepository()
        let sut = makeSUT(cameraPreviewProviderRepository: repo)
        var callCount = 0
        sut.onPublisherReady = {
            callCount += 1
        }

        sut.loadUI()
        await delay()

        #expect(callCount == 1)

        // resetPublisher nils out the publisher and emits didResetPublisher.
        // The sink delivers on the next runloop (receive on main),
        // so we set a new publisher after reset but before the delay.
        repo.resetPublisher()
        repo.publisher = .init()
        await delay()

        #expect(callCount == 2)
    }

    @Test("Given initial state, when view model is loaded, then camera devices are available")
    func loadUIShouldLoadAvailableCameraDevices() async throws {
        let cameraDevicesRepository = makeMockCameraDevicesRepository()

        let cameraDevices = [
            CameraDevice(id: "Front", name: "a name"),
            CameraDevice(id: "Back", name: "another name"),
        ]
        cameraDevicesRepository.set(cameraDevices)

        let sut = makeSUT(
            cameraDevicesRepository: cameraDevicesRepository
        )

        #expect(sut.state == .content(WaitingRoomState.initial))

        sut.loadUI()

        let expectedCameraDevices = [
            UICameraDevice(id: "Front", name: "a name", iconName: "person.fill.viewfinder"),
            UICameraDevice(id: "Back", name: "another name", iconName: "iphone.rear.camera"),
        ]

        await delay()

        switch sut.state {
        case .content(let contentState):
            #expect(contentState.cameras == expectedCameraDevices)
        default:
            Issue.record("Expected non empty cameras, got: \(sut.state)")
        }
    }

    @Test("LoadUI can be called multiple times without side effects")
    func loadUIIsIdempotent() async {
        let sut = makeSUT()

        sut.loadUI()
        sut.loadUI()

        #expect(sut.state != .loading)
    }

    @Test("Given valid username, when joining room, then no error should be displayed")
    func joinRoomWithValidUsernameShouldNotShowError() async {
        let roomName = "test-room"
        var navigateToMeetingRoom = false

        await confirmation("Should navigate to Meeting room screen") { confirm in
            let sut = makeSUT(roomName: roomName) { action in
                switch action {
                case .navigateToMeetingRoom(_):
                    navigateToMeetingRoom = true
                    confirm()
                default: break
                }
            }

            sut.userName = "ValidUser"

            await sut.joinRoom()
        }

        #expect(navigateToMeetingRoom, "Navigation should be called for valid username")
    }

    @Test("Given toggling the microphone, When the permission was denied, Then should present the Settings Alert")
    func toogleMicShouldShowSettingsMessage() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("Alert should presented for settings") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    navigateToSettingsAlert = item.title == "Check Settings"
                    confirm()
                default: break
                }
            }
            sut.onToggleMic()
        }

        #expect(navigateToSettingsAlert, "Should present Settings Alert")
    }

    @Test(
        "Given toggling the microphone presents a settings alert, When the user confirms, Then the app navigates to App Settings"
    )
    func toogleMicShouldShowSettingsMessageConfirmAndMoveToAppSetting() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    item.onConfirm?()
                case .navigateToSettings:
                    navigateToSettingsAlert = true
                    confirm()
                default: break
                }
            }
            sut.onToggleMic()
        }

        #expect(navigateToSettingsAlert, "Should present App Settings")
    }

    @Test("Given toggling the camera, When the camera permission was denied, Then should present the Settings Alert")
    func toogleCameraShouldShowSettingsMessage() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(permissionStatus: .denied)
        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("Alert Setting should presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase) {
                action in
                switch action {
                case .presentAlert(let item):
                    navigateToSettingsAlert = item.title == "Check Settings"
                    confirm()
                default: break
                }
            }
            sut.onToggleCamera()
        }

        #expect(navigateToSettingsAlert, "Should present Settings Alert")
    }

    @Test(
        "Given toggling the camera presents the Alert Settings, When the user confirms, Then the app navigates to App Settings"
    )
    func toogleCameraShouldShowSettingsMessageUserConfirmsAndNavigatesToAppSetting() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(permissionStatus: .denied)

        let roomName = "test-room"
        var navigateToSettingsAlert = false

        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(
                roomName: roomName,
                checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase
            ) { action in
                switch action {
                case .presentAlert(let item):
                    item.onConfirm?()
                case .navigateToSettings:
                    navigateToSettingsAlert = true
                    confirm()
                default: break
                }
            }
            sut.onToggleCamera()
        }

        #expect(navigateToSettingsAlert, "Should present App Settings")
    }

    // MARK: - Toolbar Buttons Tests

    @Test("Given initial state, toolbarButtons should be initialized as empty array")
    func toolbarButtonsInitializesAsEmptyArray() {
        let sut = makeSUT()

        #expect(sut.toolbarButtons.isEmpty)
    }

    @Test("Given toolbarButtons is assigned, when accessed, then it should contain the assigned value")
    func toolbarButtonsCanBeAssignedExternally() {
        let sut = makeSUT()
        let testButton = ViewHolder(id: "test-button") {
            AnyView(Text("Test Button"))
        }

        sut.toolbarButtons = [testButton]

        #expect(sut.toolbarButtons.count == 1)
        #expect(sut.toolbarButtons.first?.id == "test-button")
    }

    @Test("Given toolbarButtons and extraTrailingButtons, when both are set, then they should be independent")
    func toolbarButtonsAndExtraTrailingButtonsAreIndependent() {
        let sut = makeSUT()
        let toolbarButton = ViewHolder(id: "toolbar") {
            AnyView(Text("Toolbar"))
        }
        let trailingButton = ViewHolder(id: "trailing") {
            AnyView(Text("Trailing"))
        }

        sut.toolbarButtons = [toolbarButton]
        sut.extraTrailingButtons = [trailingButton]

        #expect(sut.toolbarButtons.count == 1)
        #expect(sut.extraTrailingButtons.count == 1)
        #expect(sut.toolbarButtons.first?.id == "toolbar")
        #expect(sut.extraTrailingButtons.first?.id == "trailing")
    }

    // MARK: - Audio Output Test Button Tests

    @Test("Given initial state, audioOutputTestButton should be nil")
    func audioOutputTestButtonInitializesAsNil() {
        let sut = makeSUT()

        #expect(sut.audioOutputTestButton == nil)
    }

    @Test("Given audioOutputTestButton is assigned, when accessed, then it should contain the assigned value")
    func audioOutputTestButtonCanBeAssignedExternally() {
        let sut = makeSUT()
        let testButton = ViewHolder(id: "audioTest") {
            Text("Audio Test")
        }

        sut.audioOutputTestButton = testButton

        #expect(sut.audioOutputTestButton != nil)
        #expect(sut.audioOutputTestButton?.id == "audioTest")
    }

    // MARK: SUT

    func makeSUT(
        roomName: RoomName = "heart-of-gold",
        cameraPreviewProviderRepository: CameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository(),
        cameraDevicesRepository: CameraDevicesRepository = makeMockCameraDevicesRepository(),
        userRepository: UserRepository = makeMockUserRepository(),
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase =
            makeMockCheckMicrophoneAuthorizationStatusUseCase(),
        advancedSettingsUseCase: PublisherAdvancedSettingsUseCase =
            makePublisherAdvancedSettingsUseCase(),
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase =
            makeMockCheckCameraAuthorizationStatusUseCase(),
        actionHandler: ActionHandler? = nil
    ) -> WaitingRoomViewModel {
        WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                advancedSettingsUseCase: advancedSettingsUseCase
            ),
            requestMicrophonePermissionUseCase: makeMockRequestMicrophonePermissionUseCase(),
            requestCameraPermissionUseCase: makeMockRequestCameraPermissionUseCase(),
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase,
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase,
            userRepository: userRepository,
            waitingRoomNavigation: MockWaitingRoomNavigation(actionHandler, roomName: roomName)
        )
    }
}
