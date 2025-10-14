//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERACore

public final class OpenTokSessionRepository<Factory: SessionFactory>: SessionRepository
where Factory.Session == OpenTokSession {

    private let sessionFactory: Factory
    private let publisherRepository: PublisherRepository
    private let pluginRegistry: OpenTokPluginRegistry

    public var currentCall: (any CallFacade)?

    public init(
        sessionFactory: Factory,
        publisherRepository: PublisherRepository,
        pluginRegistry: OpenTokPluginRegistry
    ) {
        self.sessionFactory = sessionFactory
        self.publisherRepository = publisherRepository
        self.pluginRegistry = pluginRegistry
    }

    public func createSession(_ credentials: VERACore.RoomCredentials) -> CallFacade {
        let newSession = sessionFactory.make(credentials)
        let publisher = publisherRepository.getPublisher() as! OpenTokPublisher
        let call = OpenTokCall(token: credentials.token, session: newSession, publisher: publisher)
        call.setup()
        call.registerPlugins(pluginRegistry.plugins)
        currentCall = call
        return call
    }

    public func clearSession() {
        currentCall = nil
    }
}
