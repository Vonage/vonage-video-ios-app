//
//  Created by Vonage on 03/02/2026.
//

import VERACommonUI
import VERADomain

public protocol WaitingRoomDestination {
    func presentAlertError(with message: String)

    func presentCameraPermissionAlert()

    func presentMicrophonePermissionAlert()

    func goToSettings()

    func goToMeetingRoom()
}

public struct WaitingRoomNavigation: WaitingRoomDestination {
    private let actionHandler: ActionHandler
    private let roomName: RoomName

    public init(
        actionHandler: @escaping ActionHandler,
        roomName: RoomName
    ) {
        self.actionHandler = actionHandler
        self.roomName = roomName
    }

    public func presentAlertError(with message: String) {
        let alert = AlertItem.genericError(message)
        actionHandler(.presentAlert(alert))
    }

    public func presentCameraPermissionAlert() {
        let alert = AlertItem.cameraPermissionAlert {
            goToSettings()
        }
        actionHandler(.presentAlert(alert))
    }

    public func presentMicrophonePermissionAlert() {
        let alert = AlertItem.microphonePermissionAlert {
            goToSettings()
        }
        actionHandler(.presentAlert(alert))
    }

    public func goToSettings() {
        actionHandler(.navigateToSettings)
    }

    public func goToMeetingRoom() {
        actionHandler(.navigateToMeetingRoom(roomName))
    }
}
