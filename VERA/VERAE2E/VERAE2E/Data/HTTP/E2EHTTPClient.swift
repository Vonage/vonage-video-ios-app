//
//  Created by Vonage on 7/6/26.
//

import Foundation
import VERACore
import VERADomain

public final class E2EHTTPClient: HTTPClient {
    private let store: E2EBackendStore
    private let interceptor: any HTTPClientInterceptor

    public init(
        store: E2EBackendStore = .shared,
        interceptor: any HTTPClientInterceptor
    ) {
        self.store = store
        self.interceptor = interceptor
    }

    public func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
        try await respond(to: url, method: "GET", requestBody: nil)
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
        try await respond(to: url, method: "POST", requestBody: data)
    }

    private func respond(to url: URL, method: String, requestBody: Data?) async throws -> Data {
        guard let endpoint = E2EEndpoint(rawValue: url.lastPathComponent) else {
            let responseBody = E2EHTTPResponseBuilder.errorBody(for: url.lastPathComponent)
            logFailure(
                method: method,
                url: url,
                statusCode: 404,
                requestBody: requestBody,
                responseBody: responseBody)
            throw HTTPClientError.httpError(statusCode: 404)
        }

        if E2EConfiguration.failedEndpoint == endpoint {
            let responseBody = E2EHTTPResponseBuilder.errorBody(for: endpoint.rawValue)
            logFailure(
                method: method,
                url: url,
                statusCode: 500,
                requestBody: requestBody,
                responseBody: responseBody)
            throw HTTPClientError.httpError(statusCode: 500)
        }

        let responseBody = try await store.response(for: endpoint, requestBody: requestBody)
        logSuccess(method: method, url: url, requestBody: requestBody, responseBody: responseBody)
        return responseBody
    }

    private func logSuccess(method: String, url: URL, requestBody: Data?, responseBody: Data) {
        interceptor.didSucceed(
            HTTPClientSuccessEvent(
                method: method,
                url: url,
                statusCode: 200,
                requestBodyPreview: E2EHTTPBodyPreviewSanitizer.preview(from: requestBody),
                responseBodyPreview: E2EHTTPBodyPreviewSanitizer.preview(from: responseBody)))
    }

    private func logFailure(
        method: String,
        url: URL,
        statusCode: Int,
        requestBody: Data?,
        responseBody: Data
    ) {
        interceptor.didFail(
            HTTPClientFailureEvent(
                method: method,
                url: url,
                statusCode: statusCode,
                requestBodyPreview: E2EHTTPBodyPreviewSanitizer.preview(from: requestBody),
                responseBodyPreview: E2EHTTPBodyPreviewSanitizer.preview(from: responseBody),
                errorDescription: String(describing: HTTPClientError.httpError(statusCode: statusCode))))
    }
}
