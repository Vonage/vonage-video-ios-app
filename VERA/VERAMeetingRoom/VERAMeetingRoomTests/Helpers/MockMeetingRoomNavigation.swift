//
//  Created by Vonage on 03/02/2026.
//

import VERACommonUI
import VERACore
import VERADomain
import VERAMeetingRoom

public struct MockMeetingRoomNavigation: MeetingRoomDestination {

    private let actionHandler: ActionHandler?
    private let roomName: RoomName

    public init(_ actionHandler: ActionHandler?, roomName: RoomName) {
        self.actionHandler = actionHandler
        self.roomName = roomName
    }

    public func onNext() {
        actionHandler?(.navigateToGoodbye)
    }

    public func onBack() {
        actionHandler?(.navigateToWaitingRoom(roomName))
    }

    public func presentAlertError(with message: String, shouldBack: Bool = false) {
        let alert = AlertItem.genericError(
            message
        ) {
            if shouldBack {
                onBack()
            }
        }
        actionHandler?(.presentAlert(alert))
    }

    public func presentCameraPermissionAlert() {
        let alert = AlertItem.cameraPermissionAlert {
            goToSettings()
        }
        actionHandler?(.presentAlert(alert))
    }

    public func presentMicrophonePermissionAlert() {
        let alert = AlertItem.microphonePermissionAlert {
            goToSettings()
        }
        actionHandler?(.presentAlert(alert))
    }

    public func presentForceMuteConfirmation(
        message: String,
        confirmTitle: String,
        cancelTitle: String,
        onConfirm: @escaping () -> Void
    ) {
        let alert = AlertItem(
            title: message,
            message: "",
            okAction: confirmTitle,
            cancelAction: cancelTitle,
            onConfirm: onConfirm
        )
        actionHandler?(.presentAlert(alert))
    }

    public func goToSettings() {
        actionHandler?(.navigateToSettings)
    }
}
