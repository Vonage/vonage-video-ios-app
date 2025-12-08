//
//  Created by Vonage on 4/8/25.
//

import Foundation
import Testing
import VERACore
import VERAOpenTok
import VERATestHelpers

@Suite("Default Room Credentials Repository tests")
struct DefaultRoomCredentialsRepositoryTests {

    @Test(
        "Feeding valid data into the HTTP client returns the correct credentials",
        arguments: [
            makeMockCredentials(
                sessionId: "a sessionId",
                token: "a token",
                applicationId: "an application ID",
                captionsId: "a captions ID"),
            makeMockCredentials(
                sessionId: "another sessionId",
                token: "another token",
                applicationId: "an application ID",
                captionsId: "another captions ID"),
            makeMockCredentials(
                sessionId: "another sessionId",
                token: "another token",
                applicationId: "an application ID",
                captionsId: nil),
        ])
    func getRoomCredentialsReturnsCredentials(testCase: RoomCredentials) async throws {
        let sessionId = testCase.sessionId
        let token = testCase.token
        let applicationId = testCase.applicationId
        let captionsId = testCase.captionsId

        let httpClient = MockHTTPClient()

        let responseData = try makeCredentialsJSONResponse(
            sessionId: sessionId,
            token: token,
            apiKey: applicationId,
            captionsId: captionsId)

        httpClient.data = responseData

        let sut = makeSUT(httpClient: httpClient)

        let credentials = try await sut.getRoomCredentials(makeRoomCredentialsRequest())

        #expect(credentials.sessionId == sessionId)
        #expect(credentials.token == token)
        #expect(credentials.apiKey == applicationId)
        #expect(credentials.captionsId == captionsId)
    }

    @Test func givenEmptyJSONFileErrorIsThrown() async throws {
        let httpClient = MockHTTPClient()

        httpClient.data = "{}".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        do {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
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

        httpClient.data = "".data(using: .utf8)!

        let sut = makeSUT(httpClient: httpClient)

        do {
            _ = try await sut.getRoomCredentials(makeRoomCredentialsRequest())
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

        httpClient.data = try makeCredentialsJSONResponse()

        let sut = makeSUT(httpClient: httpClient)

        let request = makeRoomCredentialsRequest()
        _ = try await sut.getRoomCredentials(request)

        #expect(httpClient.recordedURL.lastPathComponent == request.roomName)
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
