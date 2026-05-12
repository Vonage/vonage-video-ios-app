//
//  Created by Vonage on 8/2/26.
//

import Foundation
import VERADomain

struct EnableCaptionsResponse: Decodable {
    let captionsId: String?
}

public final class DefaultCaptionsDataSource: CaptionsActivationDataSource {
    private let baseURL: URL
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    public func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse {
        let url = baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("ensureCaptionsEnabled")

        let body = try jsonEncoder.encode(SessionKeyBody(sessionKey: request.sessionKey))
        let data = try await httpClient.post(url, data: body)
        let response = try jsonDecoder.decode(
            TRPCResponse<EnableCaptionsResponse>.self, from: data)

        return .init(captionsId: response.result.data.captionsId)
    }
}

private struct SessionKeyBody: Encodable {
    let sessionKey: String
}
