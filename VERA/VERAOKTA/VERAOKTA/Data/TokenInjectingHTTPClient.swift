//
//  Created by Vonage on 12/8/26.
//

import Foundation
import VERADomain

/// A lightweight decorator that injects an `Authorization: Bearer` header
/// into every request when a valid token is available.
///
/// Delegates all actual HTTP work to the wrapped client.
public final class TokenInjectingHTTPClient: HTTPClient {

    private let wrapped: any HTTPClient
    private let tokenProvider: TokenProvider

    public init(wrapped: any HTTPClient, tokenProvider: TokenProvider) {
        self.wrapped = wrapped
        self.tokenProvider = tokenProvider
    }

    public func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
        let headers = await mergeAuthHeader(into: additionalHeaders)
        return try await wrapped.get(url, additionalHeaders: headers)
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
        let headers = await mergeAuthHeader(into: additionalHeaders)
        return try await wrapped.post(url, additionalHeaders: headers, data: data)
    }

    private func mergeAuthHeader(into headers: [String: String]) async -> [String: String] {
        var merged = headers
        if let token = await tokenProvider.token() {
            merged["Authorization"] = "Bearer \(token)"
        }
        return merged
    }
}
