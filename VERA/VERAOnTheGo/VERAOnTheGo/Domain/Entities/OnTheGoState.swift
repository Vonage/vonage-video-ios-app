//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// State of the On-the-Go mode state machine.
public enum OnTheGoState: Equatable, Sendable {
    /// Normal call UI is visible; nothing is shown.
    case idle
    /// The suggestion banner is visible, waiting for the user to accept or decline.
    case suggested
    /// The audio-first On-the-Go screen is visible.
    case active
}
