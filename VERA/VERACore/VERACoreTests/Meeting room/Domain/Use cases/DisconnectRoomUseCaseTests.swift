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

        sessionRepository.currentCall = MockCall()

        #expect(sessionRepository.currentCall != nil)

        try await sut()

        let state = await sessionRepository.currentCall?.callState.values.first { $0 == .disconnected }

        #expect(sessionRepository.currentCall == nil)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        sessionRepository: SessionRepository = makeMockSessionRepository()
    ) -> DisconnectRoomUseCase {
        DisconnectRoomUseCase(sessionRepository: sessionRepository)
    }
}
