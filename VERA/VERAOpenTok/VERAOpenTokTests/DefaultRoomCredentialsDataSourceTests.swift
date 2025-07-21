//
//  Created by Vonage on 17/7/25.
//

import Foundation
import Testing
import VERAOpenTok

@Suite("Room credentials data source tests")
struct DefaultRoomCredentialsDataSourceTests {

    @Test func getRoomCredentialsReturnsCredentials() async throws {
        let sessionId = "a sessionId"
        let token = "a token"
        let apiKey = "an API key"
        let captionsId = "a captions ID"

        let httpClient = MockHTTPClient()

        let responseData = makeJSONResponse(
            sessionId: sessionId,
            token: token,
            apiKey: apiKey,
            captionsId: captionsId)

        httpClient.data = responseData

        let sut = makeSUT(httpClient: httpClient)

        let credentials = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(credentials.sessionId == sessionId)
        #expect(credentials.token == token)
        #expect(credentials.apiKey == apiKey)
        #expect(credentials.captionsId == captionsId)
    }

    @Test func getRoomCredentialsWithDifferentDataReturnsCredentials() async throws {
        let sessionId = "another sessionId"
        let token = "another token"
        let apiKey = "another API key"
        let captionsId = "another captions ID"

        let httpClient = MockHTTPClient()

        let responseData = makeJSONResponse(
            sessionId: sessionId,
            token: token,
            apiKey: apiKey,
            captionsId: captionsId)

        httpClient.data = responseData

        let sut = makeSUT(httpClient: httpClient)

        let credentials = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(credentials.sessionId == sessionId)
        #expect(credentials.token == token)
        #expect(credentials.apiKey == apiKey)
        #expect(credentials.captionsId == captionsId)
    }

    @Test func givenEmptyJSONFileErrorIsThrown() async throws {
        let httpClient = MockHTTPClient()

        httpClient.data = "{}".data(using: .utf8)

        let sut = makeSUT(httpClient: httpClient)

        do {
            let _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
            #expect(Bool(false))
        } catch {
            // Expect to fail
        }
    }

    @Test func givenARoomNameItShouldBeEncodedInHTTPRequest() async throws {
        let httpClient = MockHTTPClient()

        httpClient.data = makeJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        let request = makeRoomCredentialsRequest()
        let _ = try! await sut.getRoomCredentials(request)

        #expect(httpClient.recordedURL.lastPathComponent == request.roomName)
    }


    // MARK: - Test Helpers

    private func makeSUT(
        baseURL: URL = URL(string: "https://example.com")!,
        httpClient: MockHTTPClient = .init(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> DefaultRoomCredentialsDataSource {
        return DefaultRoomCredentialsDataSource(
            baseURL: baseURL,
            httpClient: httpClient,
            jsonDecoder: jsonDecoder)
    }

    func makeRoomCredentialsRequest(
        roomName: String = "Magrathea"
    ) -> RoomCredentialsRequest {
        RoomCredentialsRequest(roomName: roomName)
    }

    struct CredentialsSuccessfullResponse: Codable {
        let sessionId: String
        let token: String
        let apiKey: String
        let captionsId: String?
    }

    private func makeJSONResponse(
        sessionId: String = "sessionId",
        token: String = "token",
        apiKey: String = "apiKey",
        captionsId: String? = "captionsId"
    ) -> Data {
        let response = CredentialsSuccessfullResponse(
            sessionId: sessionId,
            token: token,
            apiKey: apiKey,
            captionsId: captionsId
        )

        return try! JSONEncoder().encode(response)
    }
}
