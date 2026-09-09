//
//  Created by Vonage on 9/9/26.
//

import Foundation
import Testing
import VERAConfiguration
import VERADomain

@testable import VERA

/// Covers `BaseURLResolver`: the app prefers the API URL injected through
/// `app-config.json` (`AppConfig.baseApiUrl`) and falls back to the build-time
/// `EnvironmentConstants.baseURL` when the configured value is empty or invalid.
@Suite("Base URL resolver")
struct BaseURLResolverTests {

    private let fallback = URL(string: "https://fallback.example.com/")!

    // MARK: - Pure logic (both branches)

    @Test("A valid configured URL string is used")
    func validConfiguredURLIsUsed() {
        let resolved = BaseURLResolver.resolve(
            configuredURLString: "https://configured.example.net/",
            fallback: fallback)

        #expect(resolved == URL(string: "https://configured.example.net/"))
    }

    @Test("An empty configured URL string falls back")
    func emptyConfiguredURLFallsBack() {
        let resolved = BaseURLResolver.resolve(
            configuredURLString: "",
            fallback: fallback)

        #expect(resolved == fallback)
    }

    @Test("An invalid configured URL string falls back")
    func invalidConfiguredURLFallsBack() {
        // Control characters make `URL(string:)` return nil while the string is non-empty,
        // exercising the fallback path of the non-empty branch.
        let resolved = BaseURLResolver.resolve(
            configuredURLString: "http://\u{7F} bad url",
            fallback: fallback)

        #expect(resolved == fallback)
    }

    @Test("A configured URL takes precedence over the fallback")
    func configuredURLTakesPrecedenceOverFallback() {
        let resolved = BaseURLResolver.resolve(
            configuredURLString: "https://configured.example.net/",
            fallback: fallback)

        #expect(resolved != fallback)
    }

    // MARK: - Integration: the container wires baseURL through BaseURLResolver

    @Test("Container baseURL is wired through BaseURLResolver")
    func containerBaseURLIsWiredThroughResolver() {
        let sut = DependencyContainer(httpClient: StubHTTPClient())

        let expected = BaseURLResolver.resolve(
            configuredURLString: AppConfig.baseApiUrl,
            fallback: EnvironmentConstants.baseURL)

        #expect(sut.baseURL == expected)
    }
}

/// Minimal no-op `HTTPClient` so tests don't depend on `VERATestHelpers`.
private final class StubHTTPClient: HTTPClient, @unchecked Sendable {
    func get(_ url: URL) async throws -> Data { Data() }
    func post(_ url: URL, additionalHeaders: [String: String], data: Data) async throws -> Data { Data() }
}
