//
//  Created by Vonage on 4/8/25.
//

import Foundation
import Testing
import VERACore
import VERADomain
import VERATestHelpers
import VERAVonage

@Suite("Default Room Credentials Repository tests")
struct DefaultRoomCredentialsRepositoryTests {

    @Test("Valid createSession + joinSession returns correct credentials")
    func getRoomCredentialsReturnsCredentials() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(
                sessionId: "session-123", sessionKey: "jwt-key-abc", applicationId: "app-id-42"),
            try makeJoinSessionJSONResponse(token: "token-xyz")
        ]

        let sut = makeSUT(httpClient: httpClient)

        let credentials = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(credentials.sessionId == "session-123")
        #expect(credentials.sessionKey == "jwt-key-abc")
        #expect(credentials.token == "token-xyz")
        #expect(credentials.apiKey == "app-id-42")
    }

    @Test("First call posts to /v2/createSession")
    func createSessionPostsToCorrectURL() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(httpClient.recordedURLs[0].lastPathComponent == "createSession")
        #expect(httpClient.recordedURLs[0].pathComponents.contains("v2"))
    }

    @Test("Second call posts to /v2/joinSession")
    func joinSessionPostsToCorrectURL() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(httpClient.recordedURLs[1].lastPathComponent == "joinSession")
        #expect(httpClient.recordedURLs[1].pathComponents.contains("v2"))
    }

    @Test("createSession body contains roomName")
    func createSessionBodyContainsRoomName() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "Heart-of-Gold"))

        let body = try #require(httpClient.recordedBodies[0])
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["roomName"] as? String == "Heart-of-Gold")
    }

    @Test("joinSession body contains sessionKey from createSession response")
    func joinSessionBodyContainsSessionKey() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(sessionKey: "the-jwt-key"),
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        let body = try #require(httpClient.recordedBodies[1])
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["sessionKey"] as? String == "the-jwt-key")
    }

    @Test("Empty JSON response throws decoding error")
    func givenEmptyJSONFileErrorIsThrown() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = ["{}".data(using: .utf8)!]

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
        }
    }

    @Test("Makes two POST calls total")
    func makesTwoPOSTCalls() async throws {
        let httpClient = SequentialMockHTTPClient()
        httpClient.responses = [
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(httpClient.callCount == 2)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        baseURL: URL = makeMockBaseURL(),
        httpClient: SequentialMockHTTPClient = .init(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> DefaultRoomCredentialsRepository {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)
    }

    func makeRoomCredentialsRequest(
        roomName: String = "Magrathea"
    ) -> RoomCredentialsRequest {
        RoomCredentialsRequest(roomName: roomName)
    }
}

private struct SequentialMockHTTPError: Error {}

// MARK: - Test Doubles

private final class SequentialMockHTTPClient: HTTPClient, @unchecked Sendable {
    var responses: [Data] = []
    var callCount = 0
    var recordedURLs: [URL] = []
    var recordedBodies: [Data?] = []

    func get(_ url: URL) async throws -> Data {
        fatalError("v2 API does not use GET")
    }

    func post(_ url: URL, data: Data) async throws -> Data {
        recordedURLs.append(url)
        recordedBodies.append(data)
        let index = callCount
        callCount += 1
        guard index < responses.count else {
            throw SequentialMockHTTPError()
        }
        return responses[index]
    }
}
