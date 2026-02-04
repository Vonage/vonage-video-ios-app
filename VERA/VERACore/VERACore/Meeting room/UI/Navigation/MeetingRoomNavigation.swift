//
//  Created by Vonage on 03/02/2026.
//

import VERACommonUI
import VERADomain

public protocol MeetingRoomDestination {
    func onNext()
    
    func onBack()
    
    func presentAlertError(with message: String, shouldBack: Bool)
    
    func presentCameraPermissionAlert()
    
    func presentMicrophonePermissionAlert()
    
    func goToSettings()
}

public struct MeetingRoomNavigation : MeetingRoomDestination {
    private let actionHandler: ActionHandler
    private let roomName: RoomName

    public init(
        actionHandler: @escaping ActionHandler,
        roomName: RoomName
    ) {
        self.actionHandler = actionHandler
        self.roomName = roomName
    }
    
    public func onNext() {
        actionHandler(.navigateToGoodbye)
    }
    
    public func onBack() {
        actionHandler(.navigateToWaitingRoom(roomName))
    }
    
    public func presentAlertError(with message: String, shouldBack: Bool = false) {
       let alert = AlertItem.genericError(
            message
       ){
           if shouldBack {
               onBack()
           }
       }
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
}
