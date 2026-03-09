//
//  Created by Vonage on 20/02/2026.
//

import Foundation
import Testing
import VERADomain

@testable import VERACaptions

@Suite("DefaultCaptionsDataSource Tests")
struct DefaultCaptionsDataSourceTests {

    // MARK: - Enable Captions — Success

    @Test("Enable captions builds correct URL and returns captionsId on success")
    func enableCaptionsSuccess() async throws {
        let (sut, httpClient) = makeSUT(baseURL: URL(string: "https://api.example.com")!)
        let responseJSON = """
            {"captionsId": "captions-123", "status": 200}
            """
        httpClient.postResult = .success(Data(responseJSON.utf8))

        let response = try await sut.enableCaptions(.init(roomName: "my-room"))

        #expect(response.captionsId == "captions-123")
        #expect(httpClient.postCallCount == 1)
        #expect(httpClient.lastPostURL?.absoluteString == "https://api.example.com/session/my-room/enableCaptions")
    }

    // MARK: - Enable Captions — Errors

    @Test("Enable captions throws invalidResponse when status is not 200")
    func enableCaptionsInvalidStatus() async throws {
        let (sut, httpClient) = makeSUT()
        let responseJSON = """
            {"captionsId": "captions-123", "status": 500}
            """
        httpClient.postResult = .success(Data(responseJSON.utf8))

        await #expect(throws: DefaultCaptionsDataSource.Error.self) {
            try await sut.enableCaptions(.init(roomName: "room"))
        }
    }

    @Test("Enable captions throws invalidCaptionsId when captionsId is nil")
    func enableCaptionsNilCaptionsId() async throws {
        let (sut, httpClient) = makeSUT()
        let responseJSON = """
            {"captionsId": null, "status": 200}
            """
        httpClient.postResult = .success(Data(responseJSON.utf8))

        await #expect(throws: DefaultCaptionsDataSource.Error.self) {
            try await sut.enableCaptions(.init(roomName: "room"))
        }
    }

    @Test("Enable captions throws when captionsId key is missing")
    func enableCaptionsMissingCaptionsIdKey() async throws {
        let (sut, httpClient) = makeSUT()
        let responseJSON = """
            {"status": 200}
            """
        httpClient.postResult = .success(Data(responseJSON.utf8))

        await #expect(throws: DefaultCaptionsDataSource.Error.self) {
            try await sut.enableCaptions(.init(roomName: "room"))
        }
    }

    @Test("Enable captions propagates network error from HTTP client")
    func enableCaptionsNetworkError() async throws {
        let (sut, httpClient) = makeSUT()
        httpClient.postResult = .failure(MockNetworkError.connectionFailed)

        await #expect(throws: MockNetworkError.self) {
            try await sut.enableCaptions(.init(roomName: "room"))
        }
    }

    @Test("Enable captions throws on invalid JSON response")
    func enableCaptionsInvalidJSON() async throws {
        let (sut, httpClient) = makeSUT()
        httpClient.postResult = .success(Data("not json".utf8))

        await #expect(throws: DecodingError.self) {
            try await sut.enableCaptions(.init(roomName: "room"))
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        baseURL: URL = URL(string: "https://test.api.com")!
    ) -> (DefaultCaptionsDataSource, MockHTTPClient) {
        let httpClient = MockHTTPClient()
        let sut = DefaultCaptionsDataSource(baseURL: baseURL, httpClient: httpClient)
        return (sut, httpClient)
    }
}

// MARK: - Test Doubles

private final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    var postCallCount = 0
    var lastPostURL: URL?
    var postResult: Result<Data, Error> = .success(Data())

    func get(_ url: URL) async throws -> Data {
        Data()
    }

    func post(_ url: URL, data: Data) async throws -> Data {
        postCallCount += 1
        lastPostURL = url
        return try postResult.get()
    }
}

private enum MockNetworkError: Error {
    case connectionFailed
}
