//
//  Created by Vonage on 09/06/2026.
//

import Foundation
import VERACore
import VERADomain
import VERAE2E
import VERAMeetingRoomSDK

#if OKTA_ENABLED
    import VERAOKTA
#endif

public protocol HTTPClientProvider {
    func callAsFunction() -> any HTTPClient
}

struct AppHTTPClientProvider: HTTPClientProvider {

    private let isE2EEnabled: Bool

    #if OKTA_ENABLED
        private let tokenProvider: TokenProvider?
    #endif

    #if OKTA_ENABLED
        init(isE2EEnabled: Bool, tokenProvider: TokenProvider? = nil) {
            self.isE2EEnabled = isE2EEnabled
            self.tokenProvider = tokenProvider
        }
    #else
        init(isE2EEnabled: Bool) {
            self.isE2EEnabled = isE2EEnabled
        }
    #endif

    func callAsFunction() -> any HTTPClient {
        let interceptor = OSLogHTTPClientInterceptor()

        if isE2EEnabled {
            return E2EHTTPClient(interceptor: interceptor)
        }

        let baseClient = URLSessionHTTPClient(interceptor: interceptor)

        #if OKTA_ENABLED
            if let tokenProvider {
                return TokenInjectingHTTPClient(
                    wrapped: baseClient,
                    tokenProvider: tokenProvider
                )
            }
        #endif

        return baseClient
    }
}

// MARK: - Token Injecting Decorator

#if OKTA_ENABLED
    /// A lightweight decorator that injects an `Authorization: Bearer` header
    /// into every request when a valid token is available.
    ///
    /// Delegates all actual HTTP work to the wrapped client.
    final class TokenInjectingHTTPClient: HTTPClient {

        private let wrapped: any HTTPClient
        private let tokenProvider: TokenProvider

        init(wrapped: any HTTPClient, tokenProvider: TokenProvider) {
            self.wrapped = wrapped
            self.tokenProvider = tokenProvider
        }

        func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
            let headers = await mergeAuthHeader(into: additionalHeaders)
            return try await wrapped.get(url, additionalHeaders: headers)
        }

        func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
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
#endif

struct SharedMeetingRoomHTTPClientFactory: MeetingRoomHTTPClientFactory {
    let httpClient: any HTTPClient

    func callAsFunction(_: HTTPClientContext) -> any HTTPClient {
        httpClient
    }
}
