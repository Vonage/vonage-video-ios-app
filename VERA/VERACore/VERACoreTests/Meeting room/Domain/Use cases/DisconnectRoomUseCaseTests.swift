//
//  Created by Vonage on 30/7/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("Disconnect room use case tests")
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
        sessionRepository: SessionRepository = makeMockSessionRepository()
    ) -> DisconnectRoomUseCase {
        DefaultDisconnectRoomUseCase(
            sessionRepository: sessionRepository)
    }
}
