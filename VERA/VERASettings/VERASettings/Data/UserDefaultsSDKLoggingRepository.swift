//
//  Created by Vonage on 21/05/2026.
//

import Combine
import Foundation

/// Persists ``SDKLoggingPreferences`` in `UserDefaults`.
///
/// Each value is encoded as a single JSON blob under the key
/// ``UserDefaultsSDKLoggingRepository/storeKey``.
public final class UserDefaultsSDKLoggingRepository: SDKLoggingRepository, @unchecked Sendable {

    // MARK: - Constants

    /// The UserDefaults key used to store SDK logging preferences.
    static let storeKey = "com.vonage.vera.sdkLoggingPreferences"

    // MARK: - Properties
    /// The UserDefaults instance used for persistence.
    private let userDefaults: UserDefaults

    /// Subject that holds the current preferences and notifies observers of changes.
    private nonisolated let subject = CurrentValueSubject<SDKLoggingPreferences, Never>(.default)

    /// Encoder used to serialize preferences.
    private let encoder = JSONEncoder()

    /// Decoder used to deserialize preferences.
    private let decoder = JSONDecoder()

    /// A publisher that emits the current preferences whenever they change.
    public nonisolated var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Init
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - SDKLoggingRepository

    /// Retrieves the current preferences from UserDefaults or returns the default values.
    ///
    /// - Returns: The current SDK logging preferences.
    public func getPreferences() async -> SDKLoggingPreferences {
        let initial = load(from: userDefaults) ?? subject.value
        if initial != subject.value {
            subject.send(initial)
        }
        return subject.value
    }

    /// Saves the given preferences to UserDefaults and notifies observers.
    ///
    /// - Parameter preferences: The preferences to persist.
    public func save(_ preferences: SDKLoggingPreferences) async {
        if let data = try? encoder.encode(preferences) {
            userDefaults.set(data, forKey: Self.storeKey)
        }
        subject.send(preferences)
    }

    /// Resets all preferences to their default values.
    public func reset() async {
        userDefaults.removeObject(forKey: Self.storeKey)
        subject.send(.default)
    }

    /// Loads preferences from UserDefaults synchronously.
    /// - Returns: The decoded preferences, or ``SDKLoggingPreferences/default`` if none exist.
    public func loadPreferencesSync() -> SDKLoggingPreferences {
        guard let data = userDefaults.data(forKey: UserDefaultsSDKLoggingRepository.storeKey) else { return .default }
        return (try? decoder.decode(SDKLoggingPreferences.self, from: data)) ?? .default
    }

    /// Persists preferences to UserDefaults synchronously.
    ///
    /// Used at app startup to clear the ``SDKLoggingPreferences/pendingLogCleanup``
    /// - Parameters:
    ///   - preferences: The preferences to persist.
    public func savePreferencesSync(
        _ preferences: SDKLoggingPreferences,
    ) {
        if let data = try? encoder.encode(preferences) {
            userDefaults.set(data, forKey: UserDefaultsSDKLoggingRepository.storeKey)
        }
    }

    /// Loads preferences from UserDefaults.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to read from.
    /// - Returns: The decoded preferences, or `nil` if no data exists or decoding fails.
    private func load(from userDefaults: UserDefaults) -> SDKLoggingPreferences? {
        guard let data = userDefaults.data(forKey: Self.storeKey) else { return nil }
        return try? decoder.decode(SDKLoggingPreferences.self, from: data)
    }
}
