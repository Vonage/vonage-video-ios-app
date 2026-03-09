//
//  Created by Vonage on 26/2/26.
//

import Foundation

// MARK: - UserDefaults keys

/// Stores and retrieves ``ScreenShareCredentials`` in the shared App Group `UserDefaults`.
///
/// Both the main app (writer) and the Broadcast Upload Extension (reader) use this class
/// to exchange the Vonage session credentials needed to publish a screen share stream.
public final class UserDefaultsScreenShareCredentialsRepository: ScreenShareCredentialsRepository {
    private let userDefaults: UserDefaults

    /// Creates a repository backed by the given `UserDefaults`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance to use for storage.
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public func save(_ credentials: ScreenShareCredentials) {
        userDefaults.set(credentials.applicationId, forKey: ScreenSharingKeys.applicationId)
        userDefaults.set(credentials.sessionId, forKey: ScreenSharingKeys.sessionId)
        userDefaults.set(credentials.token, forKey: ScreenSharingKeys.token)
        userDefaults.set(credentials.username, forKey: ScreenSharingKeys.username)
        userDefaults.synchronize()
    }

    public func clear() {
        userDefaults.removeObject(forKey: ScreenSharingKeys.applicationId)
        userDefaults.removeObject(forKey: ScreenSharingKeys.sessionId)
        userDefaults.removeObject(forKey: ScreenSharingKeys.token)
        userDefaults.removeObject(forKey: ScreenSharingKeys.username)
    }

    /// Reads back the stored credentials, or returns `nil` if none are present.
    public func load() -> ScreenShareCredentials? {
        guard
            let applicationId = userDefaults.string(forKey: ScreenSharingKeys.applicationId),
            let sessionId = userDefaults.string(forKey: ScreenSharingKeys.sessionId),
            let token = userDefaults.string(forKey: ScreenSharingKeys.token)
        else { return nil }
        let username = userDefaults.string(forKey: ScreenSharingKeys.username) ?? ""
        return ScreenShareCredentials(
            applicationId: applicationId,
            sessionId: sessionId,
            token: token,
            username: username)
    }
}
