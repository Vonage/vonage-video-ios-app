//
//  Created by Vonage on 14/1/26.
//

import Foundation
import VERADomain

public struct StartArchivingResponse: Codable {
    public let archiveId: String
    public let status: Int

    public init(archiveId: String, status: Int) {
        self.archiveId = archiveId
        self.status = status
    }
}

public struct StopArchivingResponse: Codable {
    public let archiveId: String
    public let status: Int

    public init(archiveId: String, status: Int) {
        self.archiveId = archiveId
        self.status = status
    }
}

public struct DefaultArchivingDataSource: ArchivingDataSource {
    private let baseURL: URL
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
    }

    public func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(request.roomName)
            .appendingPathComponent("startArchive")

        let data = try await httpClient.post(url, data: Data())
        let response = try jsonDecoder.decode(StartArchivingResponse.self, from: data)

        return .init(archiveId: response.archiveId)
    }

    public func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(request.roomName)
            .appendingPathComponent(request.archiveID)
            .appendingPathComponent("stopArchive")

        let data = try await httpClient.post(url, data: Data())
        let response = try jsonDecoder.decode(StopArchivingResponse.self, from: data)

        return .init(archiveId: response.archiveId)
    }
}
