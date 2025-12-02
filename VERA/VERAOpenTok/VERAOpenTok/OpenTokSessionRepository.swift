//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
import VERACore

public final class OpenTokSessionRepository<Factory: SessionFactory>: SessionRepository
where Factory.Session == OpenTokSession {

    enum Error: Swift.Error {
        case publisherCastingError
    }

    private var cancellables = Set<AnyCancellable>()

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

    public func createSession(_ credentials: VERACore.RoomCredentials) throws -> CallFacade {
        let newSession = try sessionFactory.make(credentials)
        guard let publisher = try publisherRepository.getPublisher() as? OpenTokPublisher else {
            throw Error.publisherCastingError
        }

        let call = OpenTokCall(credentials: credentials, session: newSession, publisher: publisher)
        call.setup()
        call.assignPlugins(pluginRegistry.plugins)
        call.callState.sink { [weak self] newState in
            guard let self, newState == .disconnected else { return }
            self.clearSession()
            self.publisherRepository.resetPublisher()
        }.store(in: &cancellables)

        currentCall = call
        return call
    }

    public func clearSession() {
        currentCall = nil
    }
}
