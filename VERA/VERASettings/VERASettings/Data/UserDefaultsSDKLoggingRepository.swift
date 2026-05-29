//
//  Created by Vonage on 21/05/2026.
//

import Combine
import Foundation

/// Persists ``SDKLoggingPreferences`` in `UserDefaults`.
///
/// Each value is encoded as a single JSON blob under the key
/// ``UserDefaultsSDKLoggingRepository/storeKey``.
public actor UserDefaultsSDKLoggingRepository: SDKLoggingRepository {

    // MARK: - Constants

    /// The UserDefaults key used to store SDK logging preferences.
    static let storeKey = "com.vonage.vera.sdkLoggingPreferences"

    // MARK: - Properties

    /// The UserDefaults instance used for persistence.
    private let userDefaults: UserDefaults

    /// Subject that holds the current preferences and notifies observers of changes.
    private nonisolated let subject: CurrentValueSubject<SDKLoggingPreferences, Never>

    /// A publisher that emits the current preferences whenever they change.
    public nonisolated var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    // MARK: - Init

    /// Creates a new UserDefaults-backed SDK logging repository.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to use. Defaults to `.standard`.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.subject = CurrentValueSubject(.default)
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
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: Self.storeKey)
            userDefaults.synchronize()
        }
        subject.send(preferences)
    }

    /// Resets all preferences to their default values.
    public func reset() async {
        userDefaults.removeObject(forKey: Self.storeKey)
        subject.send(.default)
    }

    /// Loads preferences from UserDefaults synchronously.
    ///
    /// This is safe to call from any context because `UserDefaults` is thread-safe
    /// and only `let` properties are accessed.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to read from. Defaults to `.standard`.
    /// - Returns: The decoded preferences, or ``SDKLoggingPreferences/default`` if none exist.
    public static func loadPreferencesSync(
        from userDefaults: UserDefaults = .standard
    ) -> SDKLoggingPreferences {
        guard let data = userDefaults.data(forKey: storeKey) else { return .default }
        return (try? JSONDecoder().decode(SDKLoggingPreferences.self, from: data)) ?? .default
    }

    /// Persists preferences to UserDefaults synchronously.
    ///
    /// Used at app startup to clear the ``SDKLoggingPreferences/pendingLogCleanup``
    /// flag before the actor is available.
    ///
    /// - Parameters:
    ///   - preferences: The preferences to persist.
    ///   - userDefaults: The UserDefaults instance to write to. Defaults to `.standard`.
    public static func savePreferencesSync(
        _ preferences: SDKLoggingPreferences,
        to userDefaults: UserDefaults = .standard
    ) {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: storeKey)
        }
    }

    /// Loads preferences from UserDefaults.
    ///
    /// - Parameter userDefaults: The UserDefaults instance to read from.
    /// - Returns: The decoded preferences, or `nil` if no data exists or decoding fails.
    private func load(from userDefaults: UserDefaults) -> SDKLoggingPreferences? {
        guard let data = userDefaults.data(forKey: Self.storeKey) else { return nil }
        return try? JSONDecoder().decode(SDKLoggingPreferences.self, from: data)
    }
}
