//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// Persists and retrieves screen share session credentials via a shared App Group.
///
/// Conformers write credentials when a call starts and clear them when the call ends,
/// so the Broadcast Upload Extension can read them to join the Vonage session.
public protocol ScreenShareCredentialsRepository: AnyObject {
    /// Saves credentials to the App Group shared store.
    func save(_ credentials: ScreenShareCredentials)
    /// Removes any stored credentials from the App Group shared store.
    func clear()
}
