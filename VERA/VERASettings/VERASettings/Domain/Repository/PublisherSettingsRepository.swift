//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation

/// Read/write access to persisted publisher setting preferences.
///
/// The composition root creates a concrete implementation (e.g. ``UserDefaultsSettingsRepository``)
/// and shares it between the Settings UI, the ``JoinRoomUseCase``, and the stats overlay.
public protocol PublisherSettingsRepository: Sendable {
    /// Current preferences. Always emits the current value on subscribe.
    var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> { get }

    /// Synchronous read of the current preferences.
    func getPreferences() async -> PublisherSettingsPreferences

    /// Persist updated preferences.
    func save(_ preferences: PublisherSettingsPreferences) async throws

    /// Reset all preferences to their default values.
    func reset() async
}
