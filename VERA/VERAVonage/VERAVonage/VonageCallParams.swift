//
//  Created by Vonage on 14/10/25.
//

import Foundation

/// Keys used to pass contextual call information to plugins and signal handlers.
///
/// `VonageCallParams` defines the standard parameter names included in the call
/// context dictionary (e.g., when notifying plugins via `callDidStart(_:)`).
/// These values help identify the user, the room, and the specific call instance.
public enum VonageCallParams: String {
    /// The display name of the local participant.
    case username
    /// The human-readable name of the room or session.
    case roomName
    /// A unique identifier for the call instance.
    case callID
}
