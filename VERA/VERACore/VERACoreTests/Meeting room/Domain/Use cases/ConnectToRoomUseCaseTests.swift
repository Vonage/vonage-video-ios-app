//
//  Created by Vonage on 30/7/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("Connect to room use case tests")
struct ConnectToRoomUseCaseTestsTests {

    @Test
    func connectToRoomUseCaseCreatesAndCallsToConnect() async throws {
        let httpClient = MockHTTPClient()
        httpClient.data = makeCredentialsJSONResponse()

        let getRoomCredentialsUseCase = GetRoomCredentialsUseCase(
            baseURL: makeMockBaseURL(),
            httpClient: httpClient,
            jsonDecoder: JSONDecoder())
        let sessionRepository = makeMockSessionRepository()

        let mockCall = MockCall()
        sessionRepository.currentCall = mockCall

        let sut = makeSUT(
            getRoomCredentialsUseCase: getRoomCredentialsUseCase,
            sessionRepository: sessionRepository)

        _ = try await sut(roomName: "heart-of-gold")

        #expect(sessionRepository.currentCall != nil)

        #expect(mockCall.recordedActions == [.connect])
    }

    // MARK: - Test Helpers

    private func makeSUT(
        getRoomCredentialsUseCase: GetRoomCredentialsUseCase = makeGetRoomCredentialsUseCase(),
        sessionRepository: SessionRepository = makeMockSessionRepository()
    ) -> ConnectToRoomUseCase {
        return ConnectToRoomUseCase(
            getRoomCredentialsUseCase: getRoomCredentialsUseCase,
            sessionRepository: sessionRepository)
    }
}
