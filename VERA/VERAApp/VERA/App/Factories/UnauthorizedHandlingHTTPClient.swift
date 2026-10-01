//
//  Created by Vonage on 24/9/26.
//

import Foundation
import VERACore
import VERADomain

public final class UnauthorizedHandlingHTTPClient: HTTPClient {

    private let wrapped: any HTTPClient
    private let onUnauthorized: @Sendable () async -> Void

    private actor Gate {
        private var isHandling = false
        func begin() -> Bool {
            guard !isHandling else { return false }
            isHandling = true
            return true
        }
        func end() { isHandling = false }
    }
    private let gate = Gate()

    public init(
        wrapped: any HTTPClient,
        onUnauthorized: @escaping @Sendable () async -> Void
    ) {
        self.wrapped = wrapped
        self.onUnauthorized = onUnauthorized
    }

    public func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
        do {
            return try await wrapped.get(url, additionalHeaders: additionalHeaders)
        } catch {
            throw await mapUnauthorized(error)
        }
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
        do {
            return try await wrapped.post(url, additionalHeaders: additionalHeaders, data: data)
        } catch {
            throw await mapUnauthorized(error)
        }
    }

    private func mapUnauthorized(_ error: Error) async -> Error {
        guard case HTTPClientError.httpError(statusCode: 401) = error else { return error }
        if await gate.begin() {
            await onUnauthorized()
            await gate.end()
        }
        return UnauthorizedError()
    }
}
