//
//  Created by Vonage on 26/2/26.
//

import Foundation

private enum Keys {
    static let applicationId = "screenshare_applicationId"
    static let sessionId = "screenshare_sessionId"
    static let token = "screenshare_token"
}

/// Reads Vonage session credentials written by the main app into the shared App Group.
///
/// The main app's `VonageScreenSharePlugin` writes these values on `callDidStart`,
/// and this type reads them so the broadcast extension can connect the same session.
struct UserDefaultsScreenShareCredentialsStore {
    private let userDefaults: UserDefaults

    /// Creates a store backed by the given `UserDefaults`.
    ///
    /// - Parameter userDefaults: The `UserDefaults` instance to read credentials from.
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    /// Loads stored credentials, or returns `nil` if the main app hasn't written them yet.
    func load() -> (applicationId: String, sessionId: String, token: String)? {
        guard
            let applicationId = userDefaults.string(forKey: Keys.applicationId),
            let sessionId = userDefaults.string(forKey: Keys.sessionId),
            let token = userDefaults.string(forKey: Keys.token)
        else { return nil }
        return (applicationId, sessionId, token)
    }
}
