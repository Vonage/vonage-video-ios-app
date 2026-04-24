//
//  Created by Vonage on 24/04/2026.
//

import Foundation
import Testing
import VERACommonUI
import VERADomain

@testable import VERACore

@Suite("WaitingRoomNavigation tests")
struct WaitingRoomNavigationTests {

    @Test("Given an error message, when presentAlertError is called, then a generic error alert is dispatched")
    func presentAlertErrorDispatchesGenericErrorAlert() {
        var dispatchedAction: Action?
        let sut = makeSUT { dispatchedAction = $0 }

        sut.presentAlertError(with: "Something went wrong")

        switch dispatchedAction {
        case .presentAlert(let item):
            #expect(item.title == "Error")
            #expect(item.message == "Something went wrong")
        default:
            Issue.record("Expected .presentAlert, got \(String(describing: dispatchedAction))")
        }
    }

    @Test("When presentCameraPermissionAlert is called, then a camera permission alert is dispatched")
    func presentCameraPermissionAlertDispatchesCameraAlert() {
        var dispatchedAction: Action?
        let sut = makeSUT { dispatchedAction = $0 }

        sut.presentCameraPermissionAlert()

        switch dispatchedAction {
        case .presentAlert(let item):
            #expect(item.title == "Check Settings")
            #expect(item.message == "Please review camera permissions in settings.")
        default:
            Issue.record("Expected .presentAlert, got \(String(describing: dispatchedAction))")
        }
    }

    @Test("When presentMicrophonePermissionAlert is called, then a microphone permission alert is dispatched")
    func presentMicrophonePermissionAlertDispatchesMicAlert() {
        var dispatchedAction: Action?
        let sut = makeSUT { dispatchedAction = $0 }

        sut.presentMicrophonePermissionAlert()

        switch dispatchedAction {
        case .presentAlert(let item):
            #expect(item.title == "Check Settings")
            #expect(item.message == "Please review microphone permissions in settings.")
        default:
            Issue.record("Expected .presentAlert, got \(String(describing: dispatchedAction))")
        }
    }

    @Test("When goToSettings is called, then .navigateToSettings is dispatched")
    func goToSettingsDispatchesNavigateToSettings() {
        var dispatchedAction: Action?
        let sut = makeSUT { dispatchedAction = $0 }

        sut.goToSettings()

        switch dispatchedAction {
        case .navigateToSettings:
            break
        default:
            Issue.record("Expected .navigateToSettings, got \(String(describing: dispatchedAction))")
        }
    }

    @Test("Given a room request, when goToMeetingRoom is called, then .navigateToMeetingRoom is dispatched with the request")
    func goToMeetingRoomDispatchesNavigateToMeetingRoom() {
        var dispatchedAction: Action?
        let sut = makeSUT { dispatchedAction = $0 }
        let request = NewRoomRequest(roomName: "heart-of-gold")

        sut.goToMeetingRoom(request: request)

        switch dispatchedAction {
        case .navigateToMeetingRoom(let dispatched):
            #expect(dispatched == request)
        default:
            Issue.record("Expected .navigateToMeetingRoom, got \(String(describing: dispatchedAction))")
        }
    }

    @Test("When the camera permission alert's onConfirm is called, then .navigateToSettings is dispatched")
    func cameraAlertOnConfirmNavigatesToSettings() {
        var actions: [Action] = []
        let sut = makeSUT { actions.append($0) }

        sut.presentCameraPermissionAlert()

        // Retrieve the alert's onConfirm closure and invoke it
        guard case .presentAlert(let item) = actions.first else {
            Issue.record("Expected .presentAlert as first action")
            return
        }
        item.onConfirm?()

        #expect(actions.count == 2)
        switch actions[1] {
        case .navigateToSettings:
            break
        default:
            Issue.record("Expected .navigateToSettings as second action, got \(actions[1])")
        }
    }

    @Test("When the microphone permission alert's onConfirm is called, then .navigateToSettings is dispatched")
    func microphoneAlertOnConfirmNavigatesToSettings() {
        var actions: [Action] = []
        let sut = makeSUT { actions.append($0) }

        sut.presentMicrophonePermissionAlert()

        guard case .presentAlert(let item) = actions.first else {
            Issue.record("Expected .presentAlert as first action")
            return
        }
        item.onConfirm?()

        #expect(actions.count == 2)
        switch actions[1] {
        case .navigateToSettings:
            break
        default:
            Issue.record("Expected .navigateToSettings as second action, got \(actions[1])")
        }
    }

    // MARK: - SUT

    private func makeSUT(
        roomName: RoomName = "test-room",
        actionHandler: @escaping ActionHandler = { _ in }
    ) -> WaitingRoomNavigation {
        WaitingRoomNavigation(actionHandler: actionHandler, roomName: roomName)
    }
}
