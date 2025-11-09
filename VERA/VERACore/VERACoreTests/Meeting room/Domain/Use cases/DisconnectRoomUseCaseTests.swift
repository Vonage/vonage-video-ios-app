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
    func disconnectsAndClearsSessionAndPublisher() async throws {
        let sessionRepository = makeMockSessionRepository()
        let sut = DisconnectRoomUseCase(sessionRepository: sessionRepository)

        let currentCall = MockCall()
        sessionRepository.currentCall = currentCall

        #expect(sessionRepository.currentCall != nil)

        try await sut()

        #expect(currentCall.recordedActions == [.disconnect])
    }

    // MARK: - Test Helpers

    private func makeSUT(
        sessionRepository: SessionRepository = makeMockSessionRepository()
    ) -> DisconnectRoomUseCase {
        DisconnectRoomUseCase(sessionRepository: sessionRepository)
    }
}
