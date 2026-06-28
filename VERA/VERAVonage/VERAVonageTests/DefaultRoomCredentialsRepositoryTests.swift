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
        let httpClient = try makeHTTPClientWithResponses(
            sessionId: "session-123",
            sessionKey: "jwt-key-abc",
            applicationId: "app-id-42",
            token: "token-xyz")

        let sut = makeSUT(httpClient: httpClient)

        let credentials = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(credentials.sessionId == "session-123")
        #expect(credentials.sessionKey == "jwt-key-abc")
        #expect(credentials.token == "token-xyz")
        #expect(credentials.apiKey == "app-id-42")
    }

    @Test("First call posts to /v2/createSession")
    func firstCallPostsToCreateSession() async throws {
        let httpClient = try makeHTTPClientWithResponses()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        let url = try #require(httpClient.recordedURLs.first)
        #expect(url.lastPathComponent == "createSession")
        #expect(url.pathComponents.contains("v2"))
    }

    @Test("Second call posts to /v2/joinSession")
    func secondCallPostsToJoinSession() async throws {
        let httpClient = try makeHTTPClientWithResponses()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        let url = try #require(httpClient.recordedURLs.last)
        #expect(url.lastPathComponent == "joinSession")
        #expect(url.pathComponents.contains("v2"))
    }

    @Test("createSession request body contains roomName")
    func createSessionRequestBodyContainsRoomName() async throws {
        let httpClient = try makeHTTPClientWithResponses()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "Heart-of-Gold"))

        let body = try #require(httpClient.recordedDataSequence.first)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["roomName"] as? String == "Heart-of-Gold")
    }

    @Test("joinSession request body contains sessionKey")
    func joinSessionRequestBodyContainsSessionKey() async throws {
        let httpClient = try makeHTTPClientWithResponses(sessionKey: "my-jwt")

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        let body = try #require(httpClient.recordedDataSequence.last)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["sessionKey"] as? String == "my-jwt")
    }

    @Test("Empty JSON response throws decoding error")
    func givenEmptyJSONFileErrorIsThrown() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = "{}".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
        }
    }

    @Test("Malformed joinSession response throws decoding error")
    func malformedJoinSessionResponseThrowsDecodingError() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeCreateSessionJSONResponse(),
            "{}".data(using: .utf8)!,
        ]

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: DecodingError.self) {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
        }
    }

    @Test("Makes exactly two POST calls")
    func makesTwoPostCalls() async throws {
        let httpClient = try makeHTTPClientWithResponses()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(httpClient.callCount == 2)
    }

    @Test("Different rooms are fetched independently")
    func differentRoomsAreNotCached() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse(),
            try makeCreateSessionJSONResponse(),
            try makeJoinSessionJSONResponse(),
        ]

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "roomA"))
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "roomB"))

        #expect(httpClient.callCount == 4)
    }

    @Test("Error from createSession propagates")
    func errorFromCreateSessionPropagates() async throws {
        let httpClient = MockHTTPClient()
        httpClient.shouldThrowError = true

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: MockHTTPError.self) {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
        }
    }

    @Test("Error from joinSession propagates")
    func errorFromJoinSessionPropagates() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [try makeCreateSessionJSONResponse()]
        httpClient.shouldThrowErrorOnCallNumber = 2

        let sut = makeSUT(httpClient: httpClient)

        await #expect(throws: MockHTTPError.self) {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
        }
    }

    // MARK: - getCredentialsFromSessionKey

    @Test("getCredentialsFromSessionKey calls only joinSession")
    func getCredentialsFromSessionKeyCallsOnlyJoinSession() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeJoinSessionJSONResponse(token: "token-abc", applicationId: "app-42")
        ]

        let sut = makeSUT(httpClient: httpClient)
        let sessionKey = makeTestSessionKey()
        _ = try await sut.getCredentialsFromSessionKey(.init(sessionKey: sessionKey))

        #expect(httpClient.callCount == 1)
        let url = try #require(httpClient.recordedURLs.first)
        #expect(url.lastPathComponent == "joinSession")
    }

    @Test("getCredentialsFromSessionKey returns correct token and apiKey")
    func getCredentialsFromSessionKeyReturnsCorrectCredentials() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeJoinSessionJSONResponse(token: "token-abc", applicationId: "app-42")
        ]

        let sut = makeSUT(httpClient: httpClient)
        let sessionKey = makeTestSessionKey()
        let credentials = try await sut.getCredentialsFromSessionKey(.init(sessionKey: sessionKey))

        #expect(credentials.token == "token-abc")
        #expect(credentials.apiKey == "app-42")
        #expect(credentials.sessionKey == sessionKey)
    }

    @Test("getCredentialsFromSessionKey extracts sessionId from JWT")
    func getCredentialsFromSessionKeyExtractsSessionId() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        let sessionKey = makeTestSessionKey(sessionId: "1_MX4xTest")
        let credentials = try await sut.getCredentialsFromSessionKey(.init(sessionKey: sessionKey))

        #expect(credentials.sessionId == "1_MX4xTest")
    }

    @Test("getCredentialsFromSessionKey sends sessionKey in request body")
    func getCredentialsFromSessionKeySendsSessionKey() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        let sessionKey = makeTestSessionKey()
        _ = try await sut.getCredentialsFromSessionKey(.init(sessionKey: sessionKey))

        let body = try #require(httpClient.recordedDataSequence.first)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["sessionKey"] as? String == sessionKey)
    }

    @Test("getCredentialsFromSessionKey throws when sessionId cannot be extracted")
    func getCredentialsFromSessionKeyThrowsForInvalidSessionKey() async throws {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeJoinSessionJSONResponse()
        ]

        let sut = makeSUT(httpClient: httpClient)
        let malformedSessionKey = "notajwt"
        await #expect(throws: DefaultRoomCredentialsRepository.Error.invalidSessionKey) {
            _ = try await sut.getCredentialsFromSessionKey(.init(sessionKey: malformedSessionKey))
        }
    }

    // MARK: - Test Helpers

    private func makeSUT(
        baseURL: URL = makeMockBaseURL(),
        httpClient: MockHTTPClient = .init(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> DefaultRoomCredentialsRepository {
        DefaultRoomCredentialsRepository(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)
    }

    private func makeRoomCredentialsRequest(
        roomName: String = "Magrathea"
    ) -> RoomCredentialsRequest {
        RoomCredentialsRequest(roomName: roomName)
    }

    private func makeHTTPClientWithResponses(
        sessionId: String = "sessionId",
        sessionKey: String = "sessionKey",
        applicationId: String = "applicationId",
        token: String = "token"
    ) throws -> MockHTTPClient {
        let httpClient = MockHTTPClient()
        httpClient.dataSequence = [
            try makeCreateSessionJSONResponse(
                sessionId: sessionId,
                sessionKey: sessionKey,
                applicationId: applicationId),
            try makeJoinSessionJSONResponse(
                token: token,
                applicationId: applicationId),
        ]
        return httpClient
    }

    private func makeTestSessionKey(
        sessionId: String = "1_MX4x",
        roomName: String = "solutions"
    ) -> String {
        let header = Data("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payload = Data("{\"sessionId\":\"\(sessionId)\",\"roomName\":\"\(roomName)\",\"iat\":1776844771}".utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let signature = Data("test-signature-data".utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "\(header).\(payload).\(signature)"
    }
}
