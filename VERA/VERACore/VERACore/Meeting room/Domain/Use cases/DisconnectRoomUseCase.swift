//
//  Created by Vonage on 28/7/25.
//

import Foundation

final class DisconnectRoomUseCase {

    private let sessionRepository: SessionRepository
    private let publisherRepository: PublisherRepository

    init(
        sessionRepository: SessionRepository,
        publisherRepository: PublisherRepository
    ) {
        self.sessionRepository = sessionRepository
        self.publisherRepository = publisherRepository
    }

    func callAsFunction() {
        sessionRepository.currentCall?.disconnect()
        sessionRepository.clearSession()
        publisherRepository.resetPublisher()
    }
}
