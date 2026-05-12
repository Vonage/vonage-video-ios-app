//
//  Created by Vonage on 7/5/26.
//

import Foundation
import os

/// Thread-safe holder for the session key JWT obtained after session creation.
///
/// `DefaultSessionKeyHolder` bridges the gap between synchronous factory creation
/// (in ``MeetingRoomBuilder/build()``) and asynchronous credential fetching
/// (in ``ConnectToRoomUseCase``). Feature view models receive a reference to
/// this holder at build time, and read `sessionKey` only when the user
/// triggers an action — at which point the session is always connected and
/// the key is guaranteed to be populated.
///
/// Uses `OSAllocatedUnfairLock` for safe concurrent read/write access.
public final class DefaultSessionKeyHolder: SessionKeyHolder {
    private let lock = OSAllocatedUnfairLock(initialState: "")

    /// The session key JWT used to authenticate subsequent v2 API calls.
    ///
    /// Set by ``DefaultConnectToRoomUseCase`` after credentials are fetched.
    /// Read by feature view models when the user triggers an action.
    public var sessionKey: String {
        lock.withLock { $0 }
    }

    public init() {}

    /// Updates the stored session key.
    ///
    /// - Parameter key: The JWT obtained from the `createSession` response.
    public func setSessionKey(_ key: String) {
        lock.withLock { $0 = key }
    }
}
