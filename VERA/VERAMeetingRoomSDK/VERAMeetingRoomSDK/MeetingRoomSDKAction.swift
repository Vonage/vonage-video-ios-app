//
//  Created by Vonage on 16/4/26.
//

import Foundation

/// Actions emitted by the meeting room SDK that the host app must handle.
///
/// The host app provides an action handler closure to ``MeetingRoomBuilder``
/// to receive navigation events from the meeting room.
///
/// ## Usage
/// ```swift
/// MeetingRoomBuilder(
/// baseURL: baseURL,
/// roomName: roomName)
/// .onAction { action in
///     switch action {
///         case .callDidEnd:
///             coordinator.go(to: .goodbye)
///         case .goBack(let room):
///             coordinator.go(to: .waitingRoom(room))
///         }
///     }
/// ```
public enum MeetingRoomSDKAction {
    /// The call ended and the host app should navigate to the goodbye screen.
    case callDidEnd

    /// The user should be returned to the waiting room (e.g., reconnect).
    case goBack(String)
}
