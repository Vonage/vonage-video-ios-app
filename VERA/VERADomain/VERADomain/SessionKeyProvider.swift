//
//  Created by Vonage on 12/5/26.
//

import Foundation

/// Read-only access to the session key JWT.
///
/// Feature view models depend on this protocol to read the session key
/// when the user triggers an action (e.g. start archiving, enable captions).
/// The key is guaranteed to be populated by the time it is read because
/// the call lifecycle ensures credentials are fetched before any UI action.
public protocol SessionKeyProvider: Sendable {
    /// The session key JWT used to authenticate v2 API calls.
    var sessionKey: String { get }
}

/// Write-only access to set the session key JWT.
///
/// Only ``ConnectToRoomUseCase`` (or equivalent) should conform to or use
/// this protocol — it sets the key after credentials are fetched.
public protocol SessionKeyWriter: Sendable {
    /// Updates the stored session key.
    ///
    /// - Parameter key: The JWT obtained from the `createSession` response.
    func setSessionKey(_ key: String)
}

/// Combined read/write access to the session key JWT.
public typealias SessionKeyHolder = SessionKeyProvider & SessionKeyWriter
