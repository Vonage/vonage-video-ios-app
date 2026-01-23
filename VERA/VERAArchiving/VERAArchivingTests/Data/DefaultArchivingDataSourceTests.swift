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
        let roomName = "test-room"
        let baseURL = URL(string: "https://example.com")!
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStartArchivingJSONResponse()

        let sut = makeSUT(baseURL: baseURL, httpClient: httpClient)

        _ = try await sut.startArchiving(makeStartArchivingRequest(roomName: roomName))

        let expectedURL =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(roomName)
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
        let roomName = "test-room"
        let archiveID = "archive-789"
        let baseURL = URL(string: "https://example.com")!
        let httpClient = MockHTTPClient()
        httpClient.data = try makeStopArchivingJSONResponse()

        let sut = makeSUT(baseURL: baseURL, httpClient: httpClient)

        _ = try await sut.stopArchiving(makeStopArchivingRequest(roomName: roomName, archiveID: archiveID))

        let expectedURL =
            baseURL
            .appendingPathComponent("session")
            .appendingPathComponent(roomName)
            .appendingPathComponent(archiveID)
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
        roomName: String = "test-room"
    ) -> StartArchivingDataSourceRequest {
        StartArchivingDataSourceRequest(roomName: roomName)
    }

    private func makeStopArchivingRequest(
        roomName: String = "test-room",
        archiveID: String = "archive-123"
    ) -> StopArchivingDataSourceRequest {
        StopArchivingDataSourceRequest(roomName: roomName, archiveID: archiveID)
    }

    private func makeStartArchivingJSONResponse(
        archiveId: String = "archive-123",
        status: Int = 200
    ) throws -> Data {
        let response = StartArchivingResponse(
            archiveId: archiveId,
            status: status
        )
        return try JSONEncoder().encode(response)
    }

    private func makeStopArchivingJSONResponse(
        archiveId: String = "archive-123",
        status: Int = 200
    ) throws -> Data {
        let response = StopArchivingResponse(
            archiveId: archiveId,
            status: status
        )
        return try JSONEncoder().encode(response)
    }
}
