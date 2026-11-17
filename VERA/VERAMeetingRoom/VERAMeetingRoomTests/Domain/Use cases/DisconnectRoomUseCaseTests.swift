//
//  Created by Vonage on 30/7/25.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@Suite("Disconnect room use case tests")
@MainActor
struct DisconnectRoomUseCaseTests {

    @Test
    func disconnectsCallsCallDisconnect() async throws {
        let sessionRepository = makeMockSessionRepository()

        let sut = makeSUT(sessionRepository: sessionRepository)

        let call = MockCall()
        sessionRepository.currentCall = call

        #expect(sessionRepository.currentCall != nil)

        try await sut()

        #expect(call.recordedActions == [.disconnect])
    }

    // MARK: - Test Helpers

    private func makeSUT(
        sessionRepository: SessionRepository? = nil
    ) -> DisconnectRoomUseCase {
        DefaultDisconnectRoomUseCase(
            sessionRepository: sessionRepository ?? makeMockSessionRepository())
    }
}
