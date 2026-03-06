//
//  Created by Vonage on 18/7/25.
//

import VERADomain

public struct JoinRoomRequest {
    public let roomName: String
    public let userName: String

    public init(roomName: String, userName: String) {
        self.roomName = roomName
        self.userName = userName
    }
}

public final class JoinRoomUseCase {

    private let userRepository: UserRepository
    private let cameraPreviewProviderRepository: CameraPreviewProviderRepository
    private let publisherRepository: PublisherRepository
    private let advancedSettingsUseCase: PublisherAdvancedSettingsUseCase

    public init(
        userRepository: UserRepository,
        cameraPreviewProviderRepository: CameraPreviewProviderRepository,
        publisherRepository: PublisherRepository,
        advancedSettingsUseCase: PublisherAdvancedSettingsUseCase
    ) {
        self.userRepository = userRepository
        self.cameraPreviewProviderRepository = cameraPreviewProviderRepository
        self.publisherRepository = publisherRepository
        self.advancedSettingsUseCase = advancedSettingsUseCase
    }

    @MainActor
    public func callAsFunction(_ request: JoinRoomRequest) async throws {
        let user = try await userRepository.get() ?? User(name: "")
        try await userRepository.save(user.updateName(request.userName))
        
        let currentPublisher = try cameraPreviewProviderRepository.getPublisher()

        let settings = PublisherSettings(
            username: request.userName,
            publishAudio: currentPublisher.publishAudio,
            publishVideo: currentPublisher.publishVideo,
            advancedSettings: await advancedSettingsUseCase()
        )

        currentPublisher.cleanUp()
        try publisherRepository.recreatePublisher(settings)

        let transformers = currentPublisher.videoTransformers
        let newPublisher = try publisherRepository.getPublisher()
        newPublisher.setVideoTransformers(transformers)

        cameraPreviewProviderRepository.resetPublisher()
    }
}
