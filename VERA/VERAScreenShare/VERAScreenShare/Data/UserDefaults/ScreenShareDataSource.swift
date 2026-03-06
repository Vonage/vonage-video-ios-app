//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// App Group identifier shared between the main app and the Broadcast Upload Extension.
public let veraAppGroupIdentifier = "group.com.vonage.VERA"

// MARK: - UserDefaults keys

private enum Keys {
    static let applicationId = "screenshare_applicationId"
    static let sessionId = "screenshare_sessionId"
    static let token = "screenshare_token"
}

/// Stores and retrieves ``ScreenShareCredentials`` in the shared App Group `UserDefaults`.
///
/// Both the main app (writer) and the Broadcast Upload Extension (reader) use this class
/// to exchange the Vonage session credentials needed to publish a screen share stream.
public final class UserDefaultsScreenShareCredentialsRepository: ScreenShareCredentialsRepository {
    private let userDefaults: UserDefaults

    /// Creates a repository backed by the VERA App Group.
    ///
    /// - Parameter suiteName: The App Group suite name; defaults to ``veraAppGroupIdentifier``.
    public init(suiteName: String = veraAppGroupIdentifier) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure(
                "App Group '\(suiteName)' is not configured. Add it to both the app and extension entitlements.")
        }
        self.userDefaults = defaults
    }

    public func save(_ credentials: ScreenShareCredentials) {
        userDefaults.set(credentials.applicationId, forKey: Keys.applicationId)
        userDefaults.set(credentials.sessionId, forKey: Keys.sessionId)
        userDefaults.set(credentials.token, forKey: Keys.token)
        userDefaults.synchronize()
    }

    public func clear() {
        userDefaults.removeObject(forKey: Keys.applicationId)
        userDefaults.removeObject(forKey: Keys.sessionId)
        userDefaults.removeObject(forKey: Keys.token)
    }

    /// Reads back the stored credentials, or returns `nil` if none are present.
    public func load() -> ScreenShareCredentials? {
        guard
            let applicationId = userDefaults.string(forKey: Keys.applicationId),
            let sessionId = userDefaults.string(forKey: Keys.sessionId),
            let token = userDefaults.string(forKey: Keys.token)
        else { return nil }
        return ScreenShareCredentials(applicationId: applicationId, sessionId: sessionId, token: token)
    }
}
