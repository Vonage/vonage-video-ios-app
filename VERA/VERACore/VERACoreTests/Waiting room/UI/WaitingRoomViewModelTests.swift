//
//  Created by Vonage on 16/7/25.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERADomain
import VERATestHelpers
import VERACommonUI

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

    @Test("Given invalid username, when joining room, error alert would be handled by the text field")
    func joinRoomWithInvalidUsernameShouldShowError() async {
        let roomName = "test-room"
        var isUserNameError = false
        
        await confirmation("Alert should be presented") { confirm in
            let sut = makeSUT(roomName: roomName){ action in
                switch action {
                case .presentAlert(let item):
                    isUserNameError = item.message == "Invalid User Name"
                    confirm()
                default: break
                }
            }
            
            // Set invalid username (empty or whitespace only)
            sut.userName = "   "
            
            await sut.joinRoom()
          }
        
        #expect(isUserNameError, "Error invalid user name")
    }

    @Test("Given valid username, when joining room, then no error should be displayed")
    func joinRoomWithValidUsernameShouldNotShowError() async {
        let roomName = "test-room"
        var navigateToMeetingRoom = false
        
        await confirmation("Should navigate to Meeting room screen") { confirm in
            let sut = makeSUT(roomName: roomName){ action in
                switch action {
                case .navigateToWaitingRoom(_):
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
    
    @Test("Given toogling the microphone, When the permission was denied, Then should present the Settings Alert")
    func toogleMicShouldShowSettingsMessage() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(isAuthorized: false, isDenied: true)
        
        let roomName = "test-room"
        var navigateToSettingsAlert = false
        
        await confirmation("Alert should presented for settings") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase){ action in
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
    
    @Test("Given toggling the microphone presents a settings alert, When the user confirms, Then the app navigates to App Settings")
    func toogleMicShouldShowSettingsMessageConfirmAndMoveToAppSetting() async {
        let mockCheckMicUseCase = makeMockCheckMicrophoneAuthorizationStatusUseCase(isAuthorized: false, isDenied: true)
        
        let roomName = "test-room"
        var navigateToSettingsAlert = false
        
        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkMicrophoneAuthorizationStatusUseCase: mockCheckMicUseCase){ action in
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
    
    @Test("Given toogling the camera, When the camera permission was denied, Then should present the Settings Alert")
    func toogleCameraShouldShowSettingsMessage() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(isAuthorized: false, isDenied: true)
        let roomName = "test-room"
        var navigateToSettingsAlert = false
        
        await confirmation("Alert Setting sshould presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase){ action in
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
    
    @Test("Given toggling the camera presents the Alert Settings, When the user confirms, Then the app navigates to App Settings")
    func toogleCameraShouldShowSettingsMessageUserConfirmsAndNavigatesToAppSetting() async {
        let mockCheckCameraUseCase = makeMockCheckCameraAuthorizationStatusUseCase(isAuthorized: false, isDenied: true)
        
        let roomName = "test-room"
        var navigateToSettingsAlert = false
        
        await confirmation("App settings should be presented") { confirm in
            let sut = makeSUT(roomName: roomName, checkCameraAuthorizationStatusUseCase: mockCheckCameraUseCase){ action in
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

    // MARK: SUT

    func makeSUT(
        roomName: RoomName = "heart-of-gold",
        publisherRepository: PublisherRepository = makeMockVERAPublisherRepository(),
        cameraPreviewProviderRepository: CameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository(),
        cameraDevicesRepository: CameraDevicesRepository = makeMockCameraDevicesRepository(),
        userRepository: UserRepository = makeMockUserRepository(),
        checkMicrophoneAuthorizationStatusUseCase: CheckMicrophoneAuthorizationStatusUseCase =  makeMockCheckMicrophoneAuthorizationStatusUseCase(),
        checkCameraAuthorizationStatusUseCase: CheckCameraAuthorizationStatusUseCase = makeMockCheckCameraAuthorizationStatusUseCase(),
        actionHandler: ActionHandler? = nil
    ) -> WaitingRoomViewModel {
        WaitingRoomViewModel(
            roomName: roomName,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            cameraDevicesRepository: cameraDevicesRepository,
            joinRoomUseCase: .init(
                userRepository: userRepository,
                cameraPreviewProviderRepository: cameraPreviewProviderRepository,
                publisherRepository: publisherRepository),
            requestMicrophonePermissionUseCase: makeMockRequestMicrophonePermissionUseCase(),
            requestCameraPermissionUseCase: makeMockRequestCameraPermissionUseCase(),
            checkCameraAuthorizationStatusUseCase: checkCameraAuthorizationStatusUseCase,
            checkMicrophoneAuthorizationStatusUseCase: checkMicrophoneAuthorizationStatusUseCase,
            userRepository: userRepository,
            waitinRoomNavigation: MockWaitingRoomNavigation(actionHandler, roomName: roomName))
    }
}
