//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERADomain

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        guard httpResponse.statusCode.isOK else {
            throw HTTPClientError.httpError(statusCode: httpResponse.statusCode)
        }

        return data
    }

    public func post(_ url: URL, data: Data) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (responseData, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.invalidResponse
        }

        guard httpResponse.statusCode.isOK else {
            throw HTTPClientError.httpError(statusCode: httpResponse.statusCode)
        }

        return responseData
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
