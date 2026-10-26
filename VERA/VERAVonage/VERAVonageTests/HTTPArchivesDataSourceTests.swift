//
//  Created by Vonage on 18/10/26.
//

import Foundation
import Testing
import VERADomain
import VERATestHelpers
import VERAVonage

@Suite("HTTP archives data source tests")
struct HTTPArchivesDataSourceTests {

    private let recordingID = "00000000-0000-0000-0000-000000000001"
    private let transcriptionID = "00000000-0000-0000-0000-000000000002"

    @Test("Posts the session key to /v2/searchArchives")
    func postsToSearchArchives() async throws {
        let httpClient = MockHTTPClient(data: try makeResponse(items: []))
        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.getArchives(sessionKey: "heart-of-gold")

        #expect(httpClient.recordedURL.absoluteString == "https://example.com/v2/searchArchives")
        let body = try #require(httpClient.recordedData)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json == ["sessionKey": "heart-of-gold"])
    }

    @Test("Parses a composed archive as a recording")
    func parsesRecording() async throws {
        let httpClient = MockHTTPClient(
            data: try makeResponse(items: [
                makeArchiveJSON(
                    id: recordingID,
                    status: "available",
                    outputMode: "composed",
                    url: "https://example.com/recording.mp4")
            ]))
        let sut = makeSUT(httpClient: httpClient)

        let archives = try await sut.getArchives(sessionKey: "heart-of-gold")

        let archive = try #require(archives.first)
        #expect(archive.kind == .recording)
        #expect(archive.status == .available)
        #expect(archive.createdAt == Date(timeIntervalSince1970: 1_737_395_160))
        #expect(archive.url == URL(string: "https://example.com/recording.mp4"))
        #expect(archive.transcription == nil)
    }

    @Test("Parses the nested transcription of an individual archive")
    func parsesNestedTranscription() async throws {
        let httpClient = MockHTTPClient(
            data: try makeResponse(items: [
                makeArchiveJSON(
                    id: transcriptionID,
                    status: "uploaded",
                    outputMode: "individual",
                    hasTranscription: true,
                    transcription: [
                        "status": "available",
                        "url": "https://example.com/transcript.zip",
                        "hasSummary": true,
                        "primaryLanguageCode": "en-US",
                    ])
            ]))
        let sut = makeSUT(httpClient: httpClient)

        let archives = try await sut.getArchives(sessionKey: "heart-of-gold")

        let archive = try #require(archives.first)
        #expect(archive.kind == .transcription)
        #expect(archive.status == .uploaded)
        #expect(
            archive.transcription
                == ArchiveTranscription(status: .available, url: URL(string: "https://example.com/transcript.zip")))
        #expect(archive.downloadURL == URL(string: "https://example.com/transcript.zip"))
    }

    @Test("Parses a pending transcription without a URL")
    func parsesPendingTranscription() async throws {
        let httpClient = MockHTTPClient(
            data: try makeResponse(items: [
                makeArchiveJSON(
                    id: transcriptionID,
                    status: "available",
                    outputMode: "individual",
                    hasTranscription: true,
                    transcription: ["status": "requested"])
            ]))
        let sut = makeSUT(httpClient: httpClient)

        let archive = try #require(try await sut.getArchives(sessionKey: "heart-of-gold").first)

        #expect(archive.transcription == ArchiveTranscription(status: .requested, url: nil))
        #expect(archive.isPending)
    }

    @Test("Parses every archive status", arguments: ArchiveStatus.allCases)
    func parsesStatus(status: ArchiveStatus) async throws {
        let httpClient = MockHTTPClient(
            data: try makeResponse(items: [
                makeArchiveJSON(id: recordingID, status: status.rawValue, outputMode: "composed")
            ]))
        let sut = makeSUT(httpClient: httpClient)

        let archive = try #require(try await sut.getArchives(sessionKey: "heart-of-gold").first)

        #expect(archive.status == status)
    }

    @Test("Treats an individual archive without transcription as a recording")
    func treatsIndividualArchiveWithoutTranscriptionAsRecording() async throws {
        let httpClient = MockHTTPClient(
            data: try makeResponse(items: [
                makeArchiveJSON(id: recordingID, status: "available", outputMode: "individual")
            ]))
        let sut = makeSUT(httpClient: httpClient)

        let archive = try #require(try await sut.getArchives(sessionKey: "heart-of-gold").first)

        #expect(archive.kind == .recording)
    }

    @Test("Parses an audio-only transcription archive without a resolution")
    func parsesBackendTranscriptionPayload() async throws {
        // Shape returned by searchArchives for an individual audio-only archive: no `resolution` key.
        let payload = """
            {"result":{"data":{"count":1,"items":[{"applicationId":"app","createdAt":1792398413000,
            "duration":0,"event":"archive","hasAudio":true,"hasTranscription":true,"hasVideo":false,
            "id":"7826054b-f4a3-4597-86f1-e0174b4152b8","multiArchiveTag":"transcription",
            "name":"transcription","outputMode":"individual","password":"","reason":"user initiated",
            "sessionId":"session","sha256sum":"sha","size":589,"status":"available","streamMode":"auto",
            "transcription":{"hasSummary":true,"primaryLanguageCode":"en-US",
            "reason":"no media to transcribe","status":"failed","url":null},
            "updatedAt":1792398444000,"url":"https://example.com/archive.zip"}]}}}
            """
        let sut = makeSUT(httpClient: MockHTTPClient(data: Data(payload.utf8)))

        let archive = try #require(try await sut.getArchives(sessionKey: "heart-of-gold").first)

        #expect(archive.kind == .transcription)
        #expect(archive.status == .available)
        #expect(archive.createdAt == Date(timeIntervalSince1970: 1_792_398_413))
        #expect(archive.transcription == ArchiveTranscription(status: .failed, url: nil))
        #expect(archive.downloadURL == nil)
        #expect(archive.isPending == false)
    }

    @Test("Treats an archive without hasTranscription as a recording")
    func treatsArchiveWithoutHasTranscriptionAsRecording() async throws {
        var json = makeArchiveJSON(id: recordingID, status: "available", outputMode: "individual")
        json.removeValue(forKey: "hasTranscription")
        let sut = makeSUT(httpClient: MockHTTPClient(data: try makeResponse(items: [json])))

        let archive = try #require(try await sut.getArchives(sessionKey: "heart-of-gold").first)

        #expect(archive.kind == .recording)
    }

    // MARK: - Test Helpers

    private func makeSUT(httpClient: MockHTTPClient) -> HTTPArchivesDataSource {
        HTTPArchivesDataSource(
            baseURL: URL(string: "https://example.com")!,
            httpClient: httpClient,
            jsonDecoder: JSONDecoder())
    }

    private func makeResponse(items: [[String: Any]]) throws -> Data {
        let response: [String: Any] = [
            "result": ["data": ["items": items, "count": items.count]]
        ]
        return try JSONSerialization.data(withJSONObject: response)
    }

    private func makeArchiveJSON(
        id: String,
        status: String,
        outputMode: String,
        hasTranscription: Bool = false,
        url: String? = nil,
        transcription: [String: Any]? = nil
    ) -> [String: Any] {
        var json: [String: Any] = [
            "id": id,
            "status": status,
            "name": hasTranscription ? "transcription" : "recording",
            "sessionId": "session-id",
            "applicationId": "application-id",
            "createdAt": 1_737_395_160_000,
            "size": 1_024,
            "duration": 30,
            "outputMode": outputMode,
            "streamMode": "auto",
            "hasAudio": true,
            "hasVideo": !hasTranscription,
            "hasTranscription": hasTranscription,
            "sha256sum": "sha",
            "password": "",
            "updatedAt": 1_737_395_190,
            "multiArchiveTag": hasTranscription ? "transcription" : "recording",
            "event": "archive",
            "resolution": "1920x1080",
        ]
        if let url { json["url"] = url }
        if let transcription { json["transcription"] = transcription }
        return json
    }
}
