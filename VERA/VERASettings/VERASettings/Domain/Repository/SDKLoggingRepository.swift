//
//  Created by Vonage on 21/05/2026.
//

import Combine
import Foundation

/// Read/write access to persisted SDK logging preferences.
///
/// Concrete implementations provide storage and observation for
/// ``SDKLoggingPreferences`` values used by the Settings module.
public protocol SDKLoggingRepository: Sendable {
    /// Current preferences. Always emits the current value on subscribe.
    var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> { get }

    /// Reads the current SDK logging preferences.
    func getPreferences() async -> SDKLoggingPreferences

    /// Persists updated SDK logging preferences.
    func save(_ preferences: SDKLoggingPreferences) async

    /// Resets all SDK logging preferences to their default values.
    func reset() async

    /// Loads preferences synchronously.
    func loadPreferencesSync() -> SDKLoggingPreferences

    /// Saves preferences synchronously.
    func savePreferencesSync(
        _ preferences: SDKLoggingPreferences,
    )
}
