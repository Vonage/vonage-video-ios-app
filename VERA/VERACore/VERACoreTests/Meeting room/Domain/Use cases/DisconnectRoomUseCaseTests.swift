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
        let publisherRepository = makeMockVERAPublisherRepository()
        let sut = DisconnectRoomUseCase(
            sessionRepository: sessionRepository,
            publisherRepository: publisherRepository)

        sessionRepository.currentCall = MockCall()

        #expect(sessionRepository.currentCall != nil)

        try await sut()

        #expect(sessionRepository.currentCall == nil)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        sessionRepository: SessionRepository = makeMockSessionRepository(),
        publisherRepository: PublisherRepository = makeMockVERAPublisherRepository()
    ) -> DisconnectRoomUseCase {
        DisconnectRoomUseCase(
            sessionRepository: sessionRepository,
            publisherRepository: publisherRepository)
    }
}
