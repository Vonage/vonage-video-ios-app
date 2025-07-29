//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

public final class OpenTokSessionRepository: SessionRepository {

    private let sessionFactory: OpenTokSessionFactory
    private let publisherRepository: PublisherRepository

    public var currentCall: (any CallFacade)?

    public init(
        sessionFactory: OpenTokSessionFactory,
        publisherRepository: PublisherRepository
    ) {
        self.sessionFactory = sessionFactory
        self.publisherRepository = publisherRepository
    }

    public func createSession(_ credentials: VERACore.RoomCredentials) async -> CallFacade {
        let newSession = sessionFactory.make(credentials)
        let publisher = await publisherRepository.getPublisher() as! OpenTokPublisher
        let call = OpenTokCall(token: credentials.token, session: newSession, publisher: publisher)
        call.setup()
        currentCall = call
        return call
    }

    public func clearSession() {
        currentCall = nil
    }
}
