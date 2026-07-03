//
//  Created by Vonage on 03/07/26.
//

import Foundation

/// A service that plays a short test tone through the current audio output.
///
/// Implement this protocol to provide speaker testing functionality
/// that can be verified against the device's active audio route.
public protocol SpeakerTestService: Sendable {
    /// Plays a short test tone through the current audio output route.
    func playTestSound()
}
