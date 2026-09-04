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

    public func get(_ url: URL, additionalHeaders: [String: String] = [:]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await perform(request)
    }

    public func post(_ url: URL, additionalHeaders: [String: String] = [:], data: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        additionalHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let responseData: Data
        let response: URLResponse
        let requestBodyPreview = bodyPreview(from: request.httpBody)

        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            interceptor.didFail(
                HTTPClientFailureEvent(
                    method: request.httpMethod ?? "UNKNOWN",
                    url: request.url,
                    statusCode: nil,
                    requestBodyPreview: requestBodyPreview,
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
                    requestBodyPreview: requestBodyPreview,
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
                    requestBodyPreview: requestBodyPreview,
                    responseBodyPreview: bodyPreview(from: responseData),
                    errorDescription: String(describing: error)))
            throw error
        }

        interceptor.didSucceed(
            HTTPClientSuccessEvent(
                method: request.httpMethod ?? "UNKNOWN",
                url: request.url,
                statusCode: httpResponse.statusCode,
                requestBodyPreview: requestBodyPreview,
                responseBodyPreview: bodyPreview(from: responseData)))

        return responseData
    }

    private func bodyPreview(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }

        let maxLength = 2_048
        guard let body = String(data: data, encoding: .utf8) else {
            return "<non-utf8 response body: \(data.count) bytes>"
        }

        let sanitizedBody = sanitize(body)
        guard sanitizedBody.count > maxLength else {
            return sanitizedBody
        }

        let endIndex = sanitizedBody.index(sanitizedBody.startIndex, offsetBy: maxLength)
        return "\(sanitizedBody[..<endIndex])... <truncated>"
    }

    private func sanitize(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data)
        else {
            return body
        }

        let sanitizedJSON = sanitize(json)
        guard JSONSerialization.isValidJSONObject(sanitizedJSON),
            let sanitizedData = try? JSONSerialization.data(withJSONObject: sanitizedJSON, options: [.sortedKeys]),
            let sanitizedBody = String(data: sanitizedData, encoding: .utf8)
        else {
            return body
        }

        return sanitizedBody
    }

    private func sanitize(_ value: Any) -> Any {
        if let dictionary = value as? [String: Any] {
            return dictionary.reduce(into: [String: Any]()) { result, pair in
                if sensitiveKeys.contains(pair.key.lowercased()) {
                    result[pair.key] = "<redacted>"
                } else {
                    result[pair.key] = sanitize(pair.value)
                }
            }
        }

        if let array = value as? [Any] {
            return array.map(sanitize)
        }

        return value
    }
}

private let sensitiveKeys: Set<String> = [
    "sessionkey",
    "token",
    "apikey",
    "applicationid",
    "password",
    "authorization",
    "jwt",
]

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
    public let requestBodyPreview: String?
    public let responseBodyPreview: String?
    public let errorDescription: String

    public init(
        method: String,
        url: URL?,
        statusCode: Int?,
        requestBodyPreview: String?,
        responseBodyPreview: String?,
        errorDescription: String
    ) {
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.requestBodyPreview = requestBodyPreview
        self.responseBodyPreview = responseBodyPreview
        self.errorDescription = errorDescription
    }
}

public struct HTTPClientSuccessEvent: Equatable, Sendable {
    public let method: String
    public let url: URL?
    public let statusCode: Int
    public let requestBodyPreview: String?
    public let responseBodyPreview: String?

    public init(
        method: String,
        url: URL?,
        statusCode: Int,
        requestBodyPreview: String?,
        responseBodyPreview: String?
    ) {
        self.method = method
        self.url = url
        self.statusCode = statusCode
        self.requestBodyPreview = requestBodyPreview
        self.responseBodyPreview = responseBodyPreview
    }
}

public protocol HTTPClientInterceptor: Sendable {
    func didSucceed(_ event: HTTPClientSuccessEvent)
    func didFail(_ event: HTTPClientFailureEvent)
}

extension HTTPClientInterceptor {
    public func didSucceed(_ event: HTTPClientSuccessEvent) {}
}

public struct OSLogHTTPClientInterceptor: HTTPClientInterceptor {
    private let logger: Logger

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.vonage",
        category: String = "HTTPClient"
    ) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func didSucceed(_ event: HTTPClientSuccessEvent) {
        logger.info(
            """
            HTTP request succeeded method=\(event.method, privacy: .public) \
            url=\(event.url?.absoluteString ?? "<nil>", privacy: .public) \
            status=\(String(event.statusCode), privacy: .public) \
            requestBody=\(event.requestBodyPreview ?? "<empty>", privacy: .public) \
            responseBody=\(event.responseBodyPreview ?? "<empty>", privacy: .public)
            """)
    }

    public func didFail(_ event: HTTPClientFailureEvent) {
        logger.error(
            """
            HTTP request failed method=\(event.method, privacy: .public) \
            url=\(event.url?.absoluteString ?? "<nil>", privacy: .public) \
            status=\(event.statusCode.map(String.init) ?? "<none>", privacy: .public) \
            error=\(event.errorDescription, privacy: .public) \
            requestBody=\(event.requestBodyPreview ?? "<empty>", privacy: .public) \
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
