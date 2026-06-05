//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERADomain
import os

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    private let interceptor: any HTTPClientInterceptor

    public init(
        session: URLSession = .shared,
        interceptor: any HTTPClientInterceptor
    ) {
        self.session = session
        self.interceptor = interceptor
    }

    public func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return try await perform(request)
    }

    public func post(_ url: URL, data: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let responseData: Data
        let response: URLResponse

        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            interceptor.didFail(
                HTTPClientFailureEvent(
                    method: request.httpMethod ?? "UNKNOWN",
                    url: request.url,
                    statusCode: nil,
                    responseBodyPreview: nil,
                    errorDescription: error.localizedDescription))
            throw error
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = HTTPClientError.invalidResponse
            interceptor.didFail(
                HTTPClientFailureEvent(
                    method: request.httpMethod ?? "UNKNOWN",
                    url: request.url,
                    statusCode: nil,
                    responseBodyPreview: bodyPreview(from: responseData),
                    errorDescription: String(describing: error)))
            throw error
        }

        guard httpResponse.statusCode.isOK else {
            let error = HTTPClientError.httpError(statusCode: httpResponse.statusCode)
            interceptor.didFail(
                HTTPClientFailureEvent(
                    method: request.httpMethod ?? "UNKNOWN",
                    url: request.url,
                    statusCode: httpResponse.statusCode,
                    responseBodyPreview: bodyPreview(from: responseData),
                    errorDescription: String(describing: error)))
            throw error
        }

        return responseData
    }

    private func bodyPreview(from data: Data) -> String? {
        guard !data.isEmpty else { return nil }

        let maxLength = 2_048
        let prefix = data.prefix(maxLength)
        guard let body = String(data: prefix, encoding: .utf8) else {
            return "<non-utf8 response body: \(data.count) bytes>"
        }

        return data.count > maxLength ? "\(body)... <truncated>" : body
    }
}

extension Int {
    var isOK: Bool {
        200...299 ~= self
    }
}

public enum HTTPClientError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
}

public struct HTTPClientFailureEvent: Equatable, Sendable {
    public let method: String
    public let url: URL?
    public let statusCode: Int?
    public let responseBodyPreview: String?
    public let errorDescription: String

    public init(
        method: String,
        url: URL?,
        statusCode: Int?,
        responseBodyPreview: String?,
        errorDescription: String
    ) {
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.responseBodyPreview = responseBodyPreview
        self.errorDescription = errorDescription
    }
}

public protocol HTTPClientInterceptor: Sendable {
    func didFail(_ event: HTTPClientFailureEvent)
}

public struct OSLogHTTPClientInterceptor: HTTPClientInterceptor {
    private let logger: Logger

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.vonage",
        category: String = "HTTPClient"
    ) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func didFail(_ event: HTTPClientFailureEvent) {
        logger.error(
            """
            HTTP request failed method=\(event.method, privacy: .public) \
            url=\(event.url?.absoluteString ?? "<nil>", privacy: .public) \
            status=\(event.statusCode.map(String.init) ?? "<none>", privacy: .public) \
            error=\(event.errorDescription, privacy: .public) \
            responseBody=\(event.responseBodyPreview ?? "<empty>", privacy: .public)
            """)
    }
}

extension HTTPClientError: Equatable {
    public static func == (lhs: HTTPClientError, rhs: HTTPClientError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsCode), .httpError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
}
