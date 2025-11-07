//
//  Created by Vonage on 4/11/25.
//

import Foundation
import Testing
import VERACore
import VERATestHelpers

@Suite("Joing room use case tests")
struct JoinRoomUseCaseTests {
    @Test func createsAPublisherWithPassedUsername() async throws {
        let publisherRepository = makePublisherRepositorySpy()

        let sut = makeSUT(publisherRepository: publisherRepository)
        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        try await sut(request)

        #expect(publisherRepository.actions.count == 1)

        guard case .recreate(let settings) = publisherRepository.actions[0] else {
            Issue.record("Expected .recreate action but got \(publisherRepository.actions[0])")
            return
        }

        #expect(settings.username == "Zaphod")
    }

    @Test func updatesUsernameInUserRepository() async throws {
        let userRepository = makeMockUserRepository()

        let sut = makeSUT(userRepository: userRepository)
        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        try await sut(request)

        #expect(userRepository.user?.name == "Zaphod")
    }

    @Test func resetsCameraPreviewPublisher() async throws {
        let cameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository()

        let sut = makeSUT(
            cameraPreviewProviderRepository: cameraPreviewProviderRepository)
        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        try await sut(request)

        #expect(cameraPreviewProviderRepository.actions.last == .reset)
    }

    // MARK: - Helper

    private func makeSUT(
        userRepository: UserRepository = makeMockUserRepository(),
        cameraPreviewProviderRepository: CameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository(),
        publisherRepository: PublisherRepository = makePublisherRepositorySpy()
    ) -> JoinRoomUseCase {
        JoinRoomUseCase(
            userRepository: userRepository,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            publisherRepository: publisherRepository)
    }
}
