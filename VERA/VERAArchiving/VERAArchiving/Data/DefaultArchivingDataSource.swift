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

        let isTranscription = request.kind == .transcription
        let body = try jsonEncoder.encode(
            StartArchiveBody(
                sessionKey: request.sessionKey,
                withTranscription: isTranscription ? true : nil,
                archiveOptions: isTranscription ? request.transcriptionOptions.map(ArchiveOptionsBody.init) : nil))
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

private struct StartArchiveBody: Encodable {
    let sessionKey: String
    /// Asks the backend for a post-call transcription archive instead of a recording.
    /// Omitted for recordings so the request matches backends without transcription support.
    let withTranscription: Bool?
    /// Replaces the backend's default transcription archive options. Omitted when none were chosen.
    let archiveOptions: ArchiveOptionsBody?
}

/// The complete options of a transcription archive.
private struct ArchiveOptionsBody: Encodable {
    let name = ArchiveKind.transcription.rawValue
    let multiArchiveTag = ArchiveKind.transcription.rawValue
    let outputMode = "individual"
    let hasAudio = true
    let hasVideo = false
    let hasTranscription = true
    let transcriptionProperties: TranscriptionPropertiesBody

    init(_ options: TranscriptionOptions) {
        transcriptionProperties = TranscriptionPropertiesBody(hasSummary: options.hasSummary)
    }
}

private struct TranscriptionPropertiesBody: Encodable {
    let hasSummary: Bool
}

private struct StopArchiveBody: Encodable {
    let archiveId: String
    let sessionKey: String
}
