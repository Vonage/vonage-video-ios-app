//
//  Created by Vonage on 9/9/26.
//

import Foundation
import VERADomain

/// Minimal no-op `HTTPClient` for tests that only need to construct a
/// `DependencyContainer` without performing any network work.
///
/// Declared like `MockHTTPClient` (a plain class, no `Sendable`) so it conforms to
/// `HTTPClient` under the CI build settings. Neither `HTTPClient` nor
/// `DependencyContainer` require a `Sendable` HTTP client.
final class StubHTTPClient: HTTPClient {
    func get(_ url: URL) async throws -> Data { Data() }

    func post(
        _ url: URL,
        additionalHeaders: [String: String],
        data: Data
    ) async throws -> Data {
        Data()
    }
}
