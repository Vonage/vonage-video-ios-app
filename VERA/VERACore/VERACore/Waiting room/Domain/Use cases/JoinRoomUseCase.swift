//
//  Created by Vonage on 18/7/25.
//

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
    private let publisherRepository: PublisherRepository

    public init(
        userRepository: UserRepository,
        publisherRepository: PublisherRepository
    ) {
        self.userRepository = userRepository
        self.publisherRepository = publisherRepository
    }

    public func callAsFunction(_ request: JoinRoomRequest) async throws {
        let user = try await userRepository.get() ?? User(name: "")
        try await userRepository.save(user.updateName(request.userName))

        let currentPublisher = await publisherRepository.getPublisher()

        let settings = PublisherSettings(
            username: request.userName,
            publishAudio: currentPublisher.publishAudio,
            publishVideo: currentPublisher.publishVideo
        )

        await publisherRepository.recreatePublisher(settings)
    }
}
