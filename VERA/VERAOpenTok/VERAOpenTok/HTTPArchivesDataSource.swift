//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERACore

public final class HTTPArchivesDataSource: ArchivesDataSource {
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let baseURL: URL

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
    }

    public func getArchives(
        roomName: VERACore.RoomName
    ) async throws -> [VERACore.Archive] {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appending(path: roomName)
            .appending(path: "startArchive")

        let response = try await httpClient.get(url)
        let archivesResponse = try jsonDecoder.decode(RemoteArchivesResponse.self, from: response)

        return archivesResponse.archives.map { $0.toDomain }
    }
}
