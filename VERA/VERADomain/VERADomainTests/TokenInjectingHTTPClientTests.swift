//
//  Created by Vonage on 12/8/26.
//

import Foundation
import Testing

@testable import VERADomain

@Suite("TokenInjectingHTTPClient Tests")
struct TokenInjectingHTTPClientTests {

    @Test
    func get_injectsAuthorizationHeaderWhenTokenAvailable() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: "valid-token"))

        _ = try await sut.get(anyURL())

        let headers = spy.receivedHeaders.first
        #expect(headers?["Authorization"] == "Bearer valid-token")
    }

    @Test
    func get_doesNotInjectHeaderWhenTokenIsNil() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: nil))

        _ = try await sut.get(anyURL())

        let headers = spy.receivedHeaders.first
        #expect(headers?["Authorization"] == nil)
    }

    @Test
    func get_preservesExistingHeaders() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: "a-token"))

        _ = try await sut.get(anyURL(), additionalHeaders: ["X-Custom": "value"])

        let headers = spy.receivedHeaders.first
        #expect(headers?["X-Custom"] == "value")
        #expect(headers?["Authorization"] == "Bearer a-token")
    }

    @Test
    func post_injectsAuthorizationHeaderWhenTokenAvailable() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: "post-token"))

        _ = try await sut.post(anyURL(), data: Data())

        let headers = spy.receivedHeaders.first
        #expect(headers?["Authorization"] == "Bearer post-token")
    }

    @Test
    func post_doesNotInjectHeaderWhenTokenIsNil() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: nil))

        _ = try await sut.post(anyURL(), data: Data())

        let headers = spy.receivedHeaders.first
        #expect(headers?["Authorization"] == nil)
    }

    @Test
    func post_preservesExistingHeaders() async throws {
        let spy = HTTPClientSpy()
        let sut = makeSUT(wrapped: spy, tokenProvider: MockTokenProvider(token: "a-token"))

        _ = try await sut.post(anyURL(), additionalHeaders: ["X-Request-Id": "123"], data: Data())

        let headers = spy.receivedHeaders.first
        #expect(headers?["X-Request-Id"] == "123")
        #expect(headers?["Authorization"] == "Bearer a-token")
    }

    // MARK: - Helpers

    private func makeSUT(
        wrapped: HTTPClientSpy = HTTPClientSpy(),
        tokenProvider: TokenProvider = MockTokenProvider(token: nil)
    ) -> TokenInjectingHTTPClient {
        TokenInjectingHTTPClient(wrapped: wrapped, tokenProvider: tokenProvider)
    }

    private func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }
}

// MARK: - Test Doubles

private final class HTTPClientSpy: HTTPClient {
    var receivedURLs: [URL] = []
    var receivedHeaders: [[String: String]] = []
    var receivedBodies: [Data] = []
    var stubbedData = Data()
    var stubbedError: Error?

    func get(_ url: URL, additionalHeaders: [String: String]) async throws -> Data {
        receivedURLs.append(url)
        receivedHeaders.append(additionalHeaders)
        if let error = stubbedError { throw error }
        return stubbedData
    }

    func post(_ url: URL, additionalHeaders: [String: String], data: Data) async throws -> Data {
        receivedURLs.append(url)
        receivedHeaders.append(additionalHeaders)
        receivedBodies.append(data)
        if let error = stubbedError { throw error }
        return stubbedData
    }
}

private final class MockTokenProvider: TokenProvider, @unchecked Sendable {
    private let stubbedToken: String?

    init(token: String?) {
        self.stubbedToken = token
    }

    func token() async -> String? {
        stubbedToken
    }
}
