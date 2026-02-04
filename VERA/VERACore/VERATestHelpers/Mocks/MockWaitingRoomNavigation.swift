//
//  Created by Vonage on 03/02/2026.
//

import VERACommonUI
import VERACore
import VERADomain

public struct MockWaitingRoomNavigation: WaitingRoomDestination {

    private let actionHandler: ActionHandler?
    private let roomName: RoomName

    public init(_ actionHandler: ActionHandler?, roomName: RoomName) {
        self.actionHandler = actionHandler
        self.roomName = roomName
    }

    public func presentAlertError(with message: String) {
        let alert = AlertItem.genericError(
            message
        )
        actionHandler?(.presentAlert(alert))
    }

    public func goToSettings() {
        actionHandler?(.navigateToSettings)
    }

    public func goToMeetingRoom() {
        actionHandler?(.navigateToWaitingRoom(roomName))
    }

    public func onNext() {
        actionHandler?(.navigateToGoodbye)
    }

    public func onBack() {
        actionHandler?(.navigateToWaitingRoom(roomName))
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
}
