//
//  Created by Vonage on 17/7/25.
//

import Foundation

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
