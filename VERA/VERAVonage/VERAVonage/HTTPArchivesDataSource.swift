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

/// An archive as returned by `searchArchives`.
///
/// Fields the app does not rely on are optional, so keys the API omits for some archive types
/// (such as `resolution` on audio-only transcription archives) do not break the whole list.
public struct RemoteArchive: Decodable {
    public let id: String
    public let status: String
    public let name: String
    public let reason: String?
    public let sessionId: String?
    public let applicationId: String?
    /// Milliseconds since the Unix epoch.
    public let createdAt: TimeInterval
    public let size: Int
    public let duration: Int
    public let outputMode: String
    public let streamMode: String?
    public let hasAudio: Bool?
    public let hasVideo: Bool?
    public let hasTranscription: Bool?
    public let sha256sum: String?
    public let password: String?
    public let updatedAt: TimeInterval?
    public let multiArchiveTag: String?
    public let event: String?
    public let resolution: String?
    public let url: String?
    /// Post-call transcript, present on archives started with transcription enabled.
    public let transcription: RemoteArchiveTranscription?

    /// Transcription archives are individual-stream archives with transcription enabled.
    var kind: ArchiveKind {
        outputMode == "individual" && hasTranscription == true ? .transcription : .recording
    }

    public var toDomain: Archive? {
        guard let uuid = UUID(uuidString: id) else {
            return nil
        }
        return .init(
            id: uuid,
            name: name,
            createdAt: Date(timeIntervalSince1970: createdAt / 1000),
            status: ArchiveStatus(value: status),
            url: url?.toURL,
            size: size,
            duration: duration,
            kind: kind,
            transcription: transcription?.toDomain)
    }
}

public struct RemoteArchiveTranscription: Decodable {
    public let status: String?
    public let url: String?
    public let reason: String?
    public let hasSummary: Bool?
    public let primaryLanguageCode: String?

    var toDomain: ArchiveTranscription? {
        guard let status else { return nil }
        return .init(status: ArchiveStatus(value: status), url: url?.toURL)
    }
}

extension String {
    var toURL: URL? {
        URL(string: self)
    }
}
