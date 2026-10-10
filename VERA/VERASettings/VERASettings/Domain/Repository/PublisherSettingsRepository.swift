//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import VERADomain

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

    /// Updates the saved camera while retaining the other current preferences.
    func saveCameraPosition(_ position: CameraPosition) async throws

    func saveAdvancedNoiseSuppression(_ enabled: Bool) async throws

    /// Reset all preferences to their default values.
    func reset() async
}

extension PublisherSettingsRepository {
    public func saveCameraPosition(_ position: CameraPosition) async throws {
        var preferences = await getPreferences()
        guard preferences.cameraPosition != position else { return }
        preferences.cameraPosition = position
        try await save(preferences)
    }
}

extension PublisherSettingsRepository {
    public func saveAdvancedNoiseSuppression(_ enabled: Bool) async throws {
        var preferences = await getPreferences()
        guard preferences.advancedNoiseSuppressionEnabled != enabled else { return }
        preferences.advancedNoiseSuppressionEnabled = enabled
        try await save(preferences)
    }
}
