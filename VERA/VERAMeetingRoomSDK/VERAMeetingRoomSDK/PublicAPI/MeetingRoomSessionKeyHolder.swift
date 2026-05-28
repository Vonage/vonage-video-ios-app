//
//  Created by Vonage on 28/5/26.
//

import Foundation

/// Read-only access to the session key JWT.
///
/// Implement this protocol to access the session key from the host app
/// (e.g., to make authenticated API calls from the goodbye page).
public protocol MeetingRoomSessionKeyProvider: Sendable {
    /// The session key JWT used to authenticate v2 API calls.
    var sessionKey: String { get }
}

/// Write-only access to set the session key JWT.
///
/// Only the SDK's internal connection logic uses this protocol.
public protocol MeetingRoomSessionKeyWriter: Sendable {
    /// Updates the stored session key.
    func setSessionKey(_ key: String)
}

/// Combined read/write access to the session key JWT.
public typealias MeetingRoomSessionKeyHolder = MeetingRoomSessionKeyProvider & MeetingRoomSessionKeyWriter

/// A default implementation of ``MeetingRoomSessionKeyHolder`` backed by an actor-isolated store.
public final class DefaultMeetingRoomSessionKeyHolder: MeetingRoomSessionKeyHolder, @unchecked Sendable {
    private let lock = NSLock()
    private var _sessionKey: String = ""

    public init() {}

    public var sessionKey: String {
        lock.lock()
        defer { lock.unlock() }
        return _sessionKey
    }

    public func setSessionKey(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        _sessionKey = key
    }
}

// MARK: - Internal Adapter

import VERADomain

/// Adapter that bridges the SDK's public `MeetingRoomSessionKeyHolder` to the internal `SessionKeyHolder` protocol.
struct SessionKeyHolderAdapter: VERADomain.SessionKeyProvider, VERADomain.SessionKeyWriter {
    private let holder: MeetingRoomSessionKeyHolder

    init(holder: MeetingRoomSessionKeyHolder) {
        self.holder = holder
    }

    var sessionKey: String {
        holder.sessionKey
    }

    func setSessionKey(_ key: String) {
        holder.setSessionKey(key)
    }
}
