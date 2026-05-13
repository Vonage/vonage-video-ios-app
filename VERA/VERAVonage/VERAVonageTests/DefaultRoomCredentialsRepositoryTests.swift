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

    @Test("Valid createSessionAndJoin returns correct credentials")
    func getRoomCredentialsReturnsCredentials() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeCreateSessionAndJoinJSONResponse(
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

    @Test("Posts to /v2/createSessionAndJoin")
    func postsToCorrectURL() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeCreateSessionAndJoinJSONResponse()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        let url = try #require(httpClient.recordedURL)
        #expect(url.lastPathComponent == "createSessionAndJoin")
        #expect(url.pathComponents.contains("v2"))
    }

    @Test("Request body contains roomName")
    func requestBodyContainsRoomName() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeCreateSessionAndJoinJSONResponse()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "Heart-of-Gold"))

        let body = try #require(httpClient.recordedData)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["roomName"] as? String == "Heart-of-Gold")
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

    @Test("Makes exactly one POST call")
    func makesOnePostCall() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeCreateSessionAndJoinJSONResponse()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(httpClient.callCount == 1)
    }

    @Test("Caches credentials for same room")
    func cachesCredentialsForSameRoom() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = try makeCreateSessionAndJoinJSONResponse()

        let sut = makeSUT(httpClient: httpClient)
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "room"))
        _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest(roomName: "room"))

        #expect(httpClient.callCount == 1)
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

    func makeRoomCredentialsRequest(
        roomName: String = "Magrathea"
    ) -> RoomCredentialsRequest {
        RoomCredentialsRequest(roomName: roomName)
    }
}
