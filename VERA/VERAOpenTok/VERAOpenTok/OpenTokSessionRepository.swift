//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
import VERACore

/// A concrete `SessionRepository` that constructs and manages OpenTok call sessions.
///
/// `OpenTokSessionRepository` wires together the session factory, publisher repository,
/// and the plugin registry to create a fully configured ``OpenTokCall``. It keeps track of
/// the current call, binds its lifecycle to cleanup actions, and exposes a simple API for session creation.
///
/// ## Overview
///
/// Responsibilities:
/// - Build an ``OpenTokSession`` via a generic ``SessionFactory``
/// - Resolve a concrete ``OpenTokPublisher`` from a ``PublisherRepository``
/// - Compose an ``OpenTokCall`` with plugins from ``OpenTokPluginRegistry``
/// - Track the current call and clear it when disconnected
/// - Provide a simple `createSession` API returning a ``CallFacade``
///
/// Generics:
/// - `Factory`: A `SessionFactory` producing `OpenTokSession` instances (`Factory.Session == OpenTokSession`)
public final class OpenTokSessionRepository<Factory: SessionFactory>: SessionRepository
where Factory.Session == OpenTokSession {

    /// Errors that can occur while creating a session.
    enum Error: Swift.Error {
        /// The publisher provided by `PublisherRepository` could not be cast to `OpenTokPublisher`.
        case publisherCastingError
    }

    private var cancellables = Set<AnyCancellable>()

    /// Factory used to construct OpenTok sessions for given credentials.
    private let sessionFactory: Factory
    /// Repository that provides the local media publisher instance.
    private let publisherRepository: PublisherRepository
    /// Registry containing OpenTok plugins to attach to each call.
    private let pluginRegistry: OpenTokPluginRegistry

    /// The currently active call façade, if any.
    ///
    /// Set after successful session creation; cleared on disconnect.
    public var currentCall: (any CallFacade)?

    /// Creates a new repository with its dependencies.
    ///
    /// - Parameters:
    ///   - sessionFactory: Factory that produces configured ``OpenTokSession`` instances.
    ///   - publisherRepository: Repository that yields the local publisher.
    ///   - pluginRegistry: Registry providing plugins to assign to each call.
    public init(
        sessionFactory: Factory,
        publisherRepository: PublisherRepository,
        pluginRegistry: OpenTokPluginRegistry
    ) {
        self.sessionFactory = sessionFactory
        self.publisherRepository = publisherRepository
        self.pluginRegistry = pluginRegistry
    }

    /// Creates and configures an OpenTok call session.
    ///
    /// Builds a new ``OpenTokSession`` using the factory, resolves the local publisher,
    /// constructs an ``OpenTokCall``, performs setup, assigns plugins, and binds to the
    /// call's `callState` to perform cleanup on disconnection.
    ///
    /// - Parameter credentials: Room credentials used by the session (ID, token, room name).
    /// - Returns: A configured ``CallFacade`` representing the active call.
    /// - Throws: ``Error/publisherCastingError`` if the resolved publisher is not `OpenTokPublisher`,
    ///   or any error thrown by the session factory.
    ///
    /// ## Implementation Details
    /// - Calls `sessionFactory.make(_:)` to build the session
    /// - Obtains the publisher from `publisherRepository.getPublisher()`
    /// - Creates an `OpenTokCall`, calls `setup()`, and assigns plugins
    /// - Subscribes to `call.callState` to clear session and reset publisher on disconnect
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

    /// Clears the currently tracked call.
    ///
    /// Sets ``currentCall`` to `nil`. Typically invoked after the call transitions to `.disconnected`.
    public func clearSession() {
        currentCall = nil
    }
}
