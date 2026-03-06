//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// Stores session credentials in the shared App Group so the Broadcast Upload Extension can connect.
public final class ScreenShareCredentialsUseCase {
    private let repository: ScreenShareCredentialsRepository

    public init(repository: ScreenShareCredentialsRepository) {
        self.repository = repository
    }

    /// Persists the given credentials for the broadcast extension to consume.
    public func saveCredentials(_ credentials: ScreenShareCredentials) {
        repository.save(credentials)
    }

    /// Removes stored credentials (called when the call ends).
    public func clearCredentials() {
        repository.clear()
    }
}
