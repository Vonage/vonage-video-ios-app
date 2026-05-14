//
//  Created by Vonage on 14/1/26.
//

import Foundation
import VERADomain

struct StartArchiveResponse: Decodable {
    let id: String
    let status: String
}

struct StopArchiveResponse: Decodable {
    let id: String
    let status: String
}

public struct DefaultArchivingDataSource: ArchivingDataSource {
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

    public func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        let url =
            baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("startArchive")

        let body = try jsonEncoder.encode(SessionKeyBody(sessionKey: request.sessionKey))
        let data = try await httpClient.post(url, data: body)
        let response = try jsonDecoder.decode(TRPCResponse<StartArchiveResponse>.self, from: data)

        return .init(archiveId: response.result.data.id)
    }

    public func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        let url =
            baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("stopArchive")

        let body = try jsonEncoder.encode(
            StopArchiveBody(archiveId: request.archiveID, sessionKey: request.sessionKey))
        let data = try await httpClient.post(url, data: body)
        let response = try jsonDecoder.decode(TRPCResponse<StopArchiveResponse>.self, from: data)

        return .init(archiveId: response.result.data.id)
    }
}

private struct SessionKeyBody: Encodable {
    let sessionKey: String
}

private struct StopArchiveBody: Encodable {
    let archiveId: String
    let sessionKey: String
}
