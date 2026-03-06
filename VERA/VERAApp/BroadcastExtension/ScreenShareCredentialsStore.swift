//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// App Group identifier shared between the main VERA app and this extension.
let veraAppGroupIdentifier = "group.com.vonage.VERA"

private enum Keys {
    static let applicationId = "screenshare_applicationId"
    static let sessionId = "screenshare_sessionId"
    static let token = "screenshare_token"
}

/// Reads Vonage session credentials written by the main app into the shared App Group.
///
/// The main app's `VonageScreenSharePlugin` writes these values on `callDidStart`,
/// and this type reads them so the broadcast extension can connect the same session.
struct ScreenShareCredentialsStore {
    private let userDefaults: UserDefaults

    init?() {
        guard let defaults = UserDefaults(suiteName: veraAppGroupIdentifier) else {
            return nil
        }
        self.userDefaults = defaults
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
