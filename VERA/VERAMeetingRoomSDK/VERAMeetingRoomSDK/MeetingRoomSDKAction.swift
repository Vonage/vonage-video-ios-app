//
//  Created by Vonage on 16/4/26.
//

import Foundation
import VERADomain

/// Actions emitted by the meeting room SDK that the host app must handle.
///
/// The host app provides an action handler closure to ``MeetingRoomBuilder``
/// to receive navigation and alert events from the meeting room.
///
/// ## Usage
/// ```swift
/// MeetingRoomBuilder()
///     .onAction { action in
///         switch action {
///         case .navigateToGoodbye:
///             coordinator.go(to: .goodbye)
///         case .navigateToWaitingRoom(let room):
///             coordinator.go(to: .waitingRoom(room))
///         case .presentAlert(let alert):
///             coordinator.showAlert(alert)
///         case .navigateToSettings:
///             coordinator.go(to: .settings)
///         }
///     }
/// ```
public enum MeetingRoomSDKAction {
    /// The call ended and the host app should navigate to the goodbye screen.
    case navigateToGoodbye

    /// The user should be returned to the waiting room (e.g., reconnect).
    case navigateToWaitingRoom(String)

    /// An alert should be presented to the user.
    case presentAlert(AlertItem)

    /// The user requested navigation to app settings.
    case navigateToSettings
}
