//
//  Created by Vonage on 30/7/25.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@Suite("Connect to room use case tests")
struct ConnectToRoomUseCaseTests {

    @Test
    func connectToRoomUseCaseCreatesAndCallsToConnect() async throws {
        let sessionRepository = makeMockSessionRepository()

        let mockCall = MockCall()
        sessionRepository.currentCall = mockCall

        let sut = makeSUT(sessionRepository: sessionRepository)

        _ = try await sut(roomName: "heart-of-gold")

        #expect(sessionRepository.createSessionCallCount == 1)
        #expect(mockCall.recordedActions == [.connect])
    }

    @Test
    func propagatesCreateSessionError() async throws {
        let sessionRepository = makeMockSessionRepository()
        sessionRepository.createSessionError = MockError.sessionCreationFailed

        let sut = makeSUT(sessionRepository: sessionRepository)

        await #expect(throws: MockError.self) {
            try await sut(roomName: "heart-of-gold")
        }
    }

    // MARK: - Test Helpers

    private enum MockError: Error {
        case sessionCreationFailed
    }

    private func makeSUT(
        sessionRepository: SessionRepository = makeMockSessionRepository()
    ) -> ConnectToRoomUseCase {
        DefaultConnectToRoomUseCase(sessionRepository: sessionRepository)
    }
}
