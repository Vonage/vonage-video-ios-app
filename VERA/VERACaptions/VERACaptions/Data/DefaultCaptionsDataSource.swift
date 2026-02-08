//
//  Created by Vonage on 8/2/26.
//

import Foundation
import VERADomain

public struct EnableCaptionsResponse: Codable {
    public let captionsId: String
    public let status: Int

    public init(captionsId: String, status: Int) {
        self.captionsId = captionsId
        self.status = status
    }
}

public struct DisableCaptionsResponse: Codable {
    public let disableResponse: String
    public let status: Int

    public init(disableResponse: String, status: Int) {
        self.disableResponse = disableResponse
        self.status = status
    }
}

public final class DefaultCaptionsDataSource: CaptionsDataSource {
    private let baseURL: URL
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder

    enum Error: Swift.Error {
        case invalidResponse
    }

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
    }

    public func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(request.roomName)
            .appendingPathComponent("enableCaptions")

        let data = try await httpClient.post(url, data: Data())
        let response = try jsonDecoder.decode(EnableCaptionsResponse.self, from: data)

        if response.status != 200 {
            throw Error.invalidResponse
        }

        return .init(captionsId: response.captionsId)
    }

    public func disableCaptions(
        _ request: DisableCaptionsDataSourceRequest
    ) async throws {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(request.roomName)
            .appendingPathComponent(request.captionsID)
            .appendingPathComponent("disableCaptions")

        let data = try await httpClient.post(url, data: Data())
        let response = try jsonDecoder.decode(DisableCaptionsResponse.self, from: data)

        if response.status != 200 {
            throw Error.invalidResponse
        }
    }
}
