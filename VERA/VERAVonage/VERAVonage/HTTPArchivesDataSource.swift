//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERADomain

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
        roomName: RoomName
    ) async throws -> [Archive] {
        let url =
            baseURL
            .appendingPathComponent("session")
            .appending(path: roomName)
            .appending(path: "archives")

        let response = try await httpClient.get(url)
        let archivesResponse = try jsonDecoder.decode(RemoteArchivesResponse.self, from: response)

        return archivesResponse.archives.compactMap { $0.toDomain }
    }
}

public struct RemoteArchivesResponse: Decodable {
    public let archives: [RemoteArchive]
    public let status: Int
}

public struct RemoteArchive: Decodable {
    public let id: String
    public let status: String
    public let name: String
    public let reason: String?
    public let sessionId: String
    public let applicationId: String
    public let createdAt: TimeInterval
    public let size: Int
    public let duration: Int
    public let outputMode: String
    public let streamMode: String
    public let hasAudio: Bool
    public let hasVideo: Bool
    public let hasTranscription: Bool
    public let sha256sum: String
    public let password: String
    public let updatedAt: TimeInterval
    public let multiArchiveTag: String
    public let event: String
    public let resolution: String
    public let url: String?

    public var toDomain: Archive? {
        guard let uuid = UUID(uuidString: id) else {
            return nil
        }
        return .init(
            id: uuid,
            name: name,
            createdAt: Date(timeIntervalSince1970: createdAt),
            status: ArchiveStatus(value: status),
            url: url?.toURL)
    }
}

extension String {
    var toURL: URL? {
        URL(string: self)
    }
}
