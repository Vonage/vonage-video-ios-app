//
//  Created by Vonage on 23/7/25.
//

import Combine
import Foundation
import VERACore
import VERADomain

/// A concrete `SessionRepository` that constructs and manages Vonage call sessions.
///
/// `VonageSessionRepository` wires together the session factory, publisher repository,
/// and the plugin registry to create a fully configured ``VonageCall``. It keeps track of
/// the current call, binds its lifecycle to cleanup actions, and exposes a simple API for session creation.
///
/// ## Overview
///
/// Responsibilities:
/// - Build an ``VonageSession`` via a generic ``SessionFactory``
/// - Resolve a concrete ``VonagePublisher`` from a ``PublisherRepository``
/// - Compose an ``VonageCall`` with plugins from ``VonagePluginRegistry``
/// - Track the current call and clear it when disconnected
/// - Provide a simple `createSession` API returning a ``CallFacade``
///
/// Generics:
/// - `Factory`: A `SessionFactory` producing `VonageSession` instances (`Factory.Session == VonageSession`)
public final class VonageSessionRepository<Provider: SessionProvider>: SessionRepository
where Provider.Session == VonageSession {

    /// Errors that can occur while creating a session.
    enum Error: Swift.Error {
        /// The publisher provided by `PublisherRepository` could not be cast to `VonagePublisher`.
        case publisherCastingError
    }

    private var cancellables = Set<AnyCancellable>()

    /// Provider used to construct Vonage sessions for given credentials.
    private let sessionProvider: Provider
    /// Repository that provides the local media publisher instance.
    private let publisherRepository: PublisherRepository
    /// Registry containing Vonage plugins to attach to each call.
    private let pluginRegistry: VonagePluginRegistry
    /// Network data collector audio, video and rtc data
    private let statsCollector: StatsCollector

    /// The currently active call façade, if any.
    ///
    /// Set after successful session creation; cleared on disconnect.
    public var currentCall: (any CallFacade)?

    /// Creates a new repository with its dependencies.
    ///
    /// - Parameters:
    ///   - sessionProvider: Provider that produces configured ``VonageSession`` instances.
    ///   - publisherRepository: Repository that yields the local publisher.
    ///   - pluginRegistry: Registry providing plugins to assign to each call.
    public init(
        sessionProvider: Provider,
        publisherRepository: PublisherRepository,
        pluginRegistry: VonagePluginRegistry,
        statsCollector: StatsCollector
    ) {
        self.sessionProvider = sessionProvider
        self.publisherRepository = publisherRepository
        self.pluginRegistry = pluginRegistry
        self.statsCollector = statsCollector
    }

    /// Creates and configures an Vonage call session.
    ///
    /// Resolves the local publisher, constructs an ``VonageCall`` that will build its
    /// session lazily via the injected provider, performs setup, assigns plugins, and
    /// binds to the call's `callState` to perform cleanup on disconnection.
    ///
    /// - Parameter roomName: The room to create a session for.
    /// - Returns: A configured ``CallFacade`` representing the active call.
    /// - Throws: ``Error/publisherCastingError`` if the resolved publisher is not `VonagePublisher`.
    public func createSession(for roomName: RoomName) async throws -> CallFacade {
        guard let publisher = try publisherRepository.getPublisher() as? VonagePublisher else {
            throw Error.publisherCastingError
        }

        let sessionProvider = sessionProvider
        let call = VonageCall(
            roomName: roomName,
            makeSession: { try await sessionProvider.makeSession(for: $0) },
            publisher: publisher,
            publisherRepository: publisherRepository,
            statsCollector: statsCollector
        )
        call.setup()
        call.assignPlugins(pluginRegistry.plugins)
        call.callState.sink { [weak self] newState in
            guard let self, newState == .disconnected else { return }
            self.clearSession()
            self.publisherRepository.resetPublisher()
        }
        .store(in: &cancellables)

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
