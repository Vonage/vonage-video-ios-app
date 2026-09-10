//
//  Created by Vonage on 23/7/25.
//

import Foundation

public protocol HTTPClient {
    func get(
        _ url: URL,
        additionalHeaders: [String: String]
    ) async throws -> Data

    func post(
        _ url: URL,
        additionalHeaders: [String: String],
        data: Data
    ) async throws -> Data
}

extension HTTPClient {
    public func get(_ url: URL) async throws -> Data {
        try await get(url, additionalHeaders: [:])
    }

    public func post(
        _ url: URL,
        data: Data
    ) async throws -> Data {
        try await post(
            url,
            additionalHeaders: [:],
            data: data
        )
    }
}
