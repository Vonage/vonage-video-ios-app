//
//  Created by Vonage on 23/06/2026.
//

import Combine
import Foundation

/// Null-object implementation of ``SDKLoggingRepository``.
///
/// Used when SDK logging is not configured. All reads return defaults
/// and all mutations are no-ops. ``isSupported`` returns `false`.
public actor NullSDKLoggingRepository: SDKLoggingRepository {

    public nonisolated let isSupported = false

    public nonisolated var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> {
        Just(.default).eraseToAnyPublisher()
    }

    public init() {}

    public func getPreferences() async -> SDKLoggingPreferences { .default }
    public func save(_ preferences: SDKLoggingPreferences) async {}
    public func reset() async {}
}
