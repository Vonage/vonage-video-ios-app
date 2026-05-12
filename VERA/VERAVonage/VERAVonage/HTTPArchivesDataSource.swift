//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERADomain

public final class HTTPArchivesDataSource: ArchivesDataSource {
    private let httpClient: HTTPClient
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let baseURL: URL

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        jsonDecoder: JSONDecoder,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
    }

    public func getArchives(
        sessionKey: String
    ) async throws -> [Archive] {
        let url =
            baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("searchArchives")

        let body = try jsonEncoder.encode(SessionKeyBody(sessionKey: sessionKey))
        let response = try await httpClient.post(url, data: body)
        let archivesResponse = try jsonDecoder.decode(
            TRPCResponse<SearchArchivesResponse>.self, from: response)

        return archivesResponse.result.data.items.compactMap { $0.toDomain }
    }
}

private struct SessionKeyBody: Encodable {
    let sessionKey: String
}

struct SearchArchivesResponse: Decodable {
    let items: [RemoteArchive]
    let count: Int
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
            url: url?.toURL,
            size: size,
            duration: duration)
    }
}

extension String {
    var toURL: URL? {
        URL(string: self)
    }
}
