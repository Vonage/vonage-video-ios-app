//
//  Created by Vonage on 11/11/25.
//

import Foundation
import VERACore

public func makeMockDisconnectRoomUseCase() -> MockDisconnectRoomUseCase {
    MockDisconnectRoomUseCase()
}

public final class MockDisconnectRoomUseCase: DisconnectRoomUseCase {

    public enum Actions {
        case disconnect
    }

    public var recordedActions: [Actions] = []

    public func callAsFunction() async throws {
        recordedActions.append(.disconnect)
    }
}

public func makeFailingMockDisconnectRoomUseCase(
    sessionRepository: SessionRepository,
    publisherRepository: PublisherRepository
) -> MockFailingDisconnectRoomUseCase {
    MockFailingDisconnectRoomUseCase(
        sessionRepository: sessionRepository,
        publisherRepository: publisherRepository)
}

public final class MockFailingDisconnectRoomUseCase: DisconnectRoomUseCase {
    public enum Error: Swift.Error {
        case errorMock
    }

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

        throw Error.errorMock
    }
}
