//
//  Created by Vonage on 17/7/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("Room credentials data source tests")
struct GetRoomCredentialsUseCaseTests {

    @Test(
        "Feeding valid data into the HTTP client returns the correct credentials",
        arguments: [
            MockRoomCredentials(
                sessionId: "a sessionId",
                token: "a token",
                apiKey: "an API key",
                captionsId: "a captions ID"),
            MockRoomCredentials(
                sessionId: "another sessionId",
                token: "another token",
                apiKey: "another API key",
                captionsId: "another captions ID"),
            MockRoomCredentials(
                sessionId: "another sessionId",
                token: "another token",
                apiKey: "another API key",
                captionsId: nil),
        ])
    func getRoomCredentialsReturnsCredentials(testCase: MockRoomCredentials) async throws {
        let sessionId = testCase.sessionId
        let token = testCase.token
        let apiKey = testCase.apiKey
        let captionsId = testCase.captionsId

        let httpClient = MockHTTPClient()

        let responseData = makeCredentialsJSONResponse(
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
        } catch DecodingError.keyNotFound {
            // Expect to fail
            print("error")
        } catch {
            #expect(Bool(false))
        }
    }

    @Test func givenEmptyFileErrorIsThrown() async throws {
        let httpClient = MockHTTPClient()

        httpClient.data = "".data(using: .utf8)

        let sut = makeSUT(httpClient: httpClient)

        do {
            let _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
            #expect(Bool(false))
        } catch DecodingError.dataCorrupted {
            // Expect to fail
            print("error")
        } catch {
            #expect(Bool(false))
        }
    }

    @Test func givenARoomNameItShouldBeEncodedInHTTPRequest() async throws {
        let httpClient = MockHTTPClient()

        httpClient.data = makeCredentialsJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        let request = makeRoomCredentialsRequest()
        let _ = try! await sut.getRoomCredentials(request)

        #expect(httpClient.recordedURL.lastPathComponent == request.roomName)
    }


    // MARK: - Test Helpers

    private func makeSUT(
        baseURL: URL = makeMockBaseURL(),
        httpClient: MockHTTPClient = .init(),
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> GetRoomCredentialsUseCase {
        GetRoomCredentialsUseCase(
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
