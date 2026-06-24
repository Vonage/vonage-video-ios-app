//
//  Created by Vonage on 21/05/2026.
//

import Combine
import Foundation

/// Read/write access to persisted SDK logging preferences.
///
/// Concrete implementations provide storage and observation for
/// ``SDKLoggingPreferences`` values used by the Settings module.
///
/// When SDK logging is not available, inject ``NullSDKLoggingRepository``
/// which returns `isSupported == false` and no-ops all mutations.
public protocol SDKLoggingRepository: Sendable {
    /// Whether SDK logging is supported in the current configuration.
    var isSupported: Bool { get }

    /// Current preferences. Always emits the current value on subscribe.
    var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> { get }

    /// Reads the current SDK logging preferences.
    func getPreferences() async -> SDKLoggingPreferences

    /// Persists updated SDK logging preferences.
    func save(_ preferences: SDKLoggingPreferences) async

    /// Resets all SDK logging preferences to their default values.
    func reset() async
}
