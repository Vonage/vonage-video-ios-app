//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import VERADomain

/// Persists ``PublisherSettingsPreferences`` in `UserDefaults`.
///
/// Each property of ``PublisherSettingsPreferences`` is encoded as a single
/// JSON blob under the key ``UserDefaultsSettingsRepository/storeKey``.
public actor UserDefaultsSettingsRepository: PublisherSettingsRepository {

    // MARK: - Constants

    /// The UserDefaults key used to store publisher settings preferences.
    static let storeKey = "com.vonage.vera.publisherSettingsPreferences"

    // MARK: - Properties

    /// The UserDefaults instance used for persistence.
    private let userDefaults: UserDefaults
    
    /// Subject that holds the current settings and notifies observers of changes.
    private nonisolated let subject: CurrentValueSubject<PublisherSettingsPreferences, Never>

    /// A publisher that emits the current preferences whenever they change.
    public nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Init

    /// Creates a new UserDefaults-backed settings repository.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to use. Defaults to `.standard`.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.subject = CurrentValueSubject(.default)
    }

    // MARK: - PublisherSettingsRepository

    /// Retrieves the current preferences from UserDefaults or returns the default values.
    ///
    /// If no persisted data is found, returns the default preferences.
    ///
    /// - Returns: The current publisher settings preferences.
    public func getPreferences() async -> PublisherSettingsPreferences {
        let initial = load(from: userDefaults) ?? subject.value
        if initial != subject.value {
            subject.send(initial)
        }
        return subject.value
    }

    /// Saves the given preferences to UserDefaults and notifies observers.
    ///
    /// - Parameter preferences: The preferences to persist.
    public func save(_ preferences: PublisherSettingsPreferences) async {
        if let data = try? JSONEncoder().encode(preferences) {
             userDefaults.set(data, forKey: Self.storeKey)
        }
        subject.send(preferences)
    }

    /// Resets all preferences to their default values.
    ///
    /// Removes the persisted data from UserDefaults and emits the default preferences.
    public func reset() async {
        userDefaults.removeObject(forKey: Self.storeKey)
        subject.send(.default)
    }

    /// Loads preferences from UserDefaults.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to read from.
    /// - Returns: The decoded preferences, or `nil` if no data exists or decoding fails.
    private func load(from userDefaults: UserDefaults) -> PublisherSettingsPreferences? {
        guard let data = userDefaults.data(forKey: Self.storeKey) else { return nil }
        return try? JSONDecoder().decode(PublisherSettingsPreferences.self, from: data)
    }
}
