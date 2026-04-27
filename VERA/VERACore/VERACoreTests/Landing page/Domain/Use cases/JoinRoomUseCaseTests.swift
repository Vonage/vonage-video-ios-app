//
//  Created by Vonage on 4/11/25.
//

import Foundation
import Testing
import VERACore
import VERADomain
import VERATestHelpers

@Suite("Joing room use case tests")
struct JoinRoomUseCaseTests {

    @Test func updatesUsernameInUserRepository() async throws {
        let userRepository = makeMockUserRepository()

        let sut = makeSUT(userRepository: userRepository)
        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        _ = try await sut(request)

        #expect(userRepository.actions == [.get, .save(.init(name: "Zaphod"))])
        #expect(userRepository.user?.name == "Zaphod")
    }

    @Test func resetsCameraPreviewPublisher() async throws {
        let cameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository()

        let sut = makeSUT(cameraPreviewProviderRepository: cameraPreviewProviderRepository)
        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        _ = try await sut(request)

        #expect(cameraPreviewProviderRepository.actions.last == .reset)
    }

    @Test func passesAdvancedSettingsToPublisherCreation() async throws {
        // Create specific advanced settings
        let expectedAdvancedSettings = PublisherAdvancedSettings(
            videoResolution: VideoResolution.high1080p,
            videoFrameRate: VideoFrameRate.rate30FPS,
            maxAudioBitrate: 40000,
            videoBitratePreset: VideoBitratePreset.default,
            publisherAudioFallbackEnabled: true,
            subscriberAudioFallbackEnabled: true
        )

        // Create a mock use case that returns our specific settings
        let advancedSettingsUseCase = MockPublisherAdvancedSettingsUseCaseWithSettings(
            settings: expectedAdvancedSettings
        )

        let sut = makeSUT(
            advancedSettingsUseCase: advancedSettingsUseCase
        )

        let request = JoinRoomRequest(roomName: "heart-of-gold", userName: "Zaphod")

        let newRoomRequest = try await sut(request)

        #expect(newRoomRequest.advancedSettings == expectedAdvancedSettings)
    }

    // MARK: - Helper

    private func makeSUT(
        userRepository: UserRepository = makeMockUserRepository(),
        cameraPreviewProviderRepository: CameraPreviewProviderRepository = makeMockCameraPreviewProviderRepository(),
        advancedSettingsUseCase: PublisherAdvancedSettingsUseCase = makePublisherAdvancedSettingsUseCase(),
    ) -> JoinRoomUseCase {
        JoinRoomUseCase(
            userRepository: userRepository,
            cameraPreviewProviderRepository: cameraPreviewProviderRepository,
            advancedSettingsUseCase: advancedSettingsUseCase)
    }
}
