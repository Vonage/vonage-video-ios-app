//
//  Created by Vonage on 28/7/25.
//

import Foundation

public protocol DisconnectRoomUseCase {
    func callAsFunction() async throws
}

public final class DefaultDisconnectRoomUseCase: DisconnectRoomUseCase {

    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository

    public init(
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository
    ) {
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
    }

    public func callAsFunction() async throws {
        defer {
            sessionRepository.clearSession()
            publisherRepository.resetPublisher()
        }

        try await sessionRepository.currentCall?.disconnect()
    }
}
