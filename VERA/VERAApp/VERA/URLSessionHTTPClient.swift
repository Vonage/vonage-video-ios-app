//
//  Created by Vonage on 17/7/25.
//

import Foundation
import VERAOpenTok

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(_ url: URL) async throws -> Data {
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

enum HTTPClientError: Error {
    case invalidResponse
    case httpError(statusCode: Int)
}
