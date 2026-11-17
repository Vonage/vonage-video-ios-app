//
//  Created by Vonage on 20/1/26.
//

import Foundation
import Testing
import VERAArchiving
import VERADomain
import VERATestHelpers

@Suite("Default archiving data source tests")
struct DefaultArchivingDataSourceTests {

    // MARK: - Start Archiving Tests

    @Test("Start archiving returns correct archive ID")
    func startArchivingReturnsCorrectArchiveID() async throws {
        let expectedArchiveId = "archive-123"
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse(archiveId: expectedArchiveId)

        let sut = makeSUT(httpClient: httpClient)

        let response = try await sut.startArchiving(makeStartArchivingRequest())

        #expect(response.archiveId == expectedArchiveId)
    }

    @Test("Start archiving constructs correct URL")
    func startArchivingConstructsCorrectURL() async throws {
        let baseURL = URL(string: "https://example.com")!
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(baseURL: baseURL, httpClient: httpClient)

        _ = try await sut.startArchiving(makeStartArchivingRequest())

        let expectedURL =
            baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("startArchive")

        #expect(httpClient.recordedURL == expectedURL)
    }

    @Test("Start archiving uses POST method")
    func startArchivingUsesPOSTMethod() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(makeStartArchivingRequest())

        #expect(httpClient.callCount == 1)
        #expect(httpClient.recordedData != nil)
    }

    @Test("Start recording omits withTranscription from the request body")
    func startRecordingOmitsWithTranscription() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(makeStartArchivingRequest(kind: .recording))

        let body = try recordedBody(httpClient)
        #expect(body["sessionKey"] as? String == "test-session-key")
        #expect(body["withTranscription"] == nil)
    }

    @Test("Start transcription sends withTranscription true in the request body")
    func startTranscriptionSendsWithTranscription() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(makeStartArchivingRequest(kind: .transcription))

        let body = try recordedBody(httpClient)
        #expect(body["sessionKey"] as? String == "test-session-key")
        #expect(body["withTranscription"] as? Bool == true)
        #expect(body["archiveOptions"] == nil)
    }

    @Test(
        "Start transcription sends the chosen summary option as archive options",
        arguments: [
            TranscriptionOptions(hasSummary: true),
            TranscriptionOptions(hasSummary: false),
        ])
    func startTranscriptionSendsChosenOptions(options: TranscriptionOptions) async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(
            makeStartArchivingRequest(kind: .transcription, transcriptionOptions: options))

        let body = try recordedBody(httpClient)
        let archiveOptions = try #require(body["archiveOptions"] as? [String: Any])
        let properties = try #require(archiveOptions["transcriptionProperties"] as? [String: Any])
        #expect(body["withTranscription"] as? Bool == true)
        #expect(archiveOptions["hasTranscription"] as? Bool == true)
        #expect(properties["hasSummary"] as? Bool == options.hasSummary)
        #expect(properties["primaryLanguageCode"] == nil)
    }

    /// The backend replaces its default transcription archive options with the request's,
    /// so a partial set makes Vonage reject the archive.
    @Test("Start transcription sends the complete transcription archive options")
    func startTranscriptionSendsCompleteArchiveOptions() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(
            makeStartArchivingRequest(kind: .transcription, transcriptionOptions: .default))

        let body = try recordedBody(httpClient)
        let archiveOptions = try #require(body["archiveOptions"] as? [String: Any])
        #expect(archiveOptions["name"] as? String == "transcription")
        #expect(archiveOptions["multiArchiveTag"] as? String == "transcription")
        #expect(archiveOptions["outputMode"] as? String == "individual")
        #expect(archiveOptions["hasAudio"] as? Bool == true)
        #expect(archiveOptions["hasVideo"] as? Bool == false)
        #expect(archiveOptions["hasTranscription"] as? Bool == true)
        #expect(archiveOptions["transcriptionProperties"] != nil)
    }

    @Test("Start recording never sends transcription archive options")
    func startRecordingIgnoresTranscriptionOptions() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.startArchiving(
            makeStartArchivingRequest(kind: .recording, transcriptionOptions: .default))

        let body = try recordedBody(httpClient)
        #expect(body["withTranscription"] == nil)
        #expect(body["archiveOptions"] == nil)
    }

    @Test("Start archiving throws error on invalid JSON")
    func startArchivingThrowsErrorOnInvalidJSON() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = "invalid json".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.startArchiving(makeStartArchivingRequest())
        }
    }

    @Test("Start archiving throws error on empty response")
    func startArchivingThrowsErrorOnEmptyResponse() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = "{}".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.startArchiving(makeStartArchivingRequest())
        }
    }

    @Test("Start archiving throws error when HTTP client fails")
    func startArchivingThrowsErrorWhenHTTPClientFails() async throws {
        let httpClient = MockHTTPClient()
        httpClient.shouldThrowError = true

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: MockHTTPError.self) {
            _ = try await sut.startArchiving(makeStartArchivingRequest())
        }
    }

    // MARK: - Stop Archiving Tests

    @Test("Stop archiving returns correct archive ID")
    func stopArchivingReturnsCorrectArchiveID() async throws {
        let expectedArchiveId = "archive-456"
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStopArchivingJSONResponse(archiveId: expectedArchiveId)

        let sut = makeSUT(httpClient: httpClient)

        let response = try await sut.stopArchiving(makeStopArchivingRequest())

        #expect(response.archiveId == expectedArchiveId)
    }

    @Test("Stop archiving constructs correct URL")
    func stopArchivingConstructsCorrectURL() async throws {
        let baseURL = URL(string: "https://example.com")!
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStopArchivingJSONResponse()

        let sut = makeSUT(baseURL: baseURL, httpClient: httpClient)

        _ = try await sut.stopArchiving(makeStopArchivingRequest())

        let expectedURL =
            baseURL
            .appendingPathComponent("v2")
            .appendingPathComponent("stopArchive")

        #expect(httpClient.recordedURL == expectedURL)
    }

    @Test("Stop archiving uses POST method")
    func stopArchivingUsesPOSTMethod() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStopArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.stopArchiving(makeStopArchivingRequest())

        #expect(httpClient.callCount == 1)
        #expect(httpClient.recordedData != nil)
    }

    @Test("Stop transcription sends the explicit archive id in the request body")
    func stopTranscriptionSendsArchiveID() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStopArchivingJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        _ = try await sut.stopArchiving(
            StopArchivingDataSourceRequest(
                sessionKey: "test-session-key",
                archiveID: "transcription-1",
                kind: .transcription))

        let body = try recordedBody(httpClient)
        #expect(body["archiveId"] as? String == "transcription-1")
        #expect(body["sessionKey"] as? String == "test-session-key")
    }

    @Test("Stop archiving throws error on invalid JSON")
    func stopArchivingThrowsErrorOnInvalidJSON() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = "invalid json".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.stopArchiving(makeStopArchivingRequest())
        }
    }

    @Test("Stop archiving throws error on empty response")
    func stopArchivingThrowsErrorOnEmptyResponse() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = "{}".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.stopArchiving(makeStopArchivingRequest())
        }
    }

    @Test("Stop archiving throws error when HTTP client fails")
    func stopArchivingThrowsErrorWhenHTTPClientFails() async throws {
        let httpClient = MockHTTPClient()
        httpClient.shouldThrowError = true

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: MockHTTPError.self) {
            _ = try await sut.stopArchiving(makeStopArchivingRequest())
        }
    }

    // MARK: - Test Helpers

    private func makeSUT(
        baseURL: URL = makeMockBaseURL(),
        httpClient: HTTPClient = MockHTTPClient(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> DefaultArchivingDataSource {
        DefaultArchivingDataSource(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)
    }

    private func makeStartArchivingRequest(
        sessionKey: String = "test-session-key",
        kind: ArchiveKind = .recording,
        transcriptionOptions: TranscriptionOptions? = nil
    ) -> StartArchivingDataSourceRequest {
        StartArchivingDataSourceRequest(
            sessionKey: sessionKey, kind: kind, transcriptionOptions: transcriptionOptions)
    }

    private func recordedBody(_ httpClient: MockHTTPClient) throws -> [String: Any] {
        let data = try #require(httpClient.recordedData)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func makeStopArchivingRequest(
        sessionKey: String = "test-session-key",
        archiveID: String = "archive-123"
    ) -> StopArchivingDataSourceRequest {
        StopArchivingDataSourceRequest(sessionKey: sessionKey, archiveID: archiveID)
    }

    private func makeStartArchivingJSONResponse(
        archiveId: String = "archive-123"
    ) throws -> Data {
        let json: [String: Any] = [
            "result": [
                "data": [
                    "id": archiveId,
                    "status": "started",
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: json)
    }

    private func makeStopArchivingJSONResponse(
        archiveId: String = "archive-123"
    ) throws -> Data {
        let json: [String: Any] = [
            "result": [
                "data": [
                    "id": archiveId,
                    "status": "stopped",
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: json)
    }
}
