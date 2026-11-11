//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import VERACaptions
import VERADomain
import VERAVonage

/// Bridges the captions feature between the Vonage SDK and the application's domain layer.
///
/// `VonageCaptionsPlugin` is a call-lifecycle plugin that performs two jobs:
///
/// 1. **Activation relay** – Observes the ``CaptionsStatusDataSource`` and tells the
///    ``CallFacade`` to enable or disable SDK-level captions whenever the local user
///    toggles the feature from the UI.
/// 2. **Caption forwarding** – Subscribes to the ``CallFacade/captionsPublisher`` and
///    writes every update to the ``CaptionsWriter`` so that downstream view models
///    can display live transcription text.
///
/// Both subscriptions are established when the call starts and torn down when it ends.
///
/// ## Lifecycle
/// ```
/// callDidStart   ──► initObservers()
///                       ├─ subscribe to captionsStatusDataSource.captionsState
///                       └─ subscribe to call.captionsPublisher
///
/// callDidEnd     ──► cancelObservables()
///                       ├─ reset captionsStatusDataSource
///                       ├─ clear captionsRepository
///                       └─ cancel all Combine subscriptions
/// ```
///
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallHolder``, ``CaptionsStatusDataSource``
public final class VonageCaptionsPlugin: VonagePlugin, VonagePluginCallHolder {
    private var cancellables = Set<AnyCancellable>()
    /// Ordered consumers of the two subscriptions, cancelled or drained on call end.
    private var stateTask: Task<Void, Never>?
    private var captionsTask: Task<Void, Never>?

    /// The active call façade, injected by the plugin coordinator after initialisation.
    ///
    /// Used to call ``CallFacade/enableCaptions()`` and
    /// ``CallFacade/disableCaptions()`` as well as to subscribe to
    /// ``CallFacade/captionsPublisher``.
    public weak var call: (any CallFacade)?

    /// Reactive source of the current captions activation state (`.enabled` / `.disabled`).
    private let captionsStatusDataSource: CaptionsStatusDataSource

    /// Write-only entry point into the captions repository used to push live caption data
    /// so that ``CaptionsViewModel`` can display it.
    private let captionsRepository: CaptionsWriter

    /// A stable identifier for this plugin instance.
    ///
    /// Defaults to the type name (e.g., `"VonageCaptionsPlugin"`).
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new captions plugin instance.
    ///
    /// - Parameters:
    ///   - captionsStatusDataSource: The data source for captions activation state.
    ///   - captionsRepository: The writer to forward caption data to.
    public init(
        captionsStatusDataSource: CaptionsStatusDataSource,
        captionsRepository: CaptionsWriter
    ) {
        self.captionsStatusDataSource = captionsStatusDataSource
        self.captionsRepository = captionsRepository
    }

    /// Called when the call starts and the Vonage session is connected.
    ///
    /// Sets up two Combine subscriptions:
    /// - **Captions state** – enables or disables SDK captions in response to
    ///   ``CaptionsStatusDataSource/captionsState`` changes.
    /// - **Caption data** – forwards ``CallFacade/captionsPublisher`` updates
    ///   to the ``CaptionsWriter``.
    ///
    /// - Parameter userInfo: Contextual info passed by the plugin coordinator
    ///   (not used by this plugin).
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        initObservers()
    }

    /// Called when the call ends and the Vonage session is disconnecting.
    ///
    /// Performs cleanup in order:
    /// 1. Resets ``CaptionsStatusDataSource`` to `.disabled`.
    /// 2. Clears any remaining captions in the repository.
    /// 3. Cancels all active Combine subscriptions to prevent further updates.
    public func callDidEnd() async throws {
        try await cancelObservables()
    }

    // MARK: - Private

    /// Tears down all state related to the current call session.
    private func cancelObservables() async throws {
        // Pending caption snapshots are obsolete once the call ends; a write already running finishes.
        captionsTask?.cancel()
        captionsStatusDataSource.reset()
        // Cancelling the subscriptions finishes both streams, so the state task applies
        // the `.disabled` emitted by `reset()` and then ends.
        cancellables.removeAll()
        await captionsTask?.value
        await stateTask?.value
        captionsTask = nil
        stateTask = nil
        await captionsRepository.updateCaptions([])
    }

    /// Creates the two pipelines that power this plugin.
    private func initObservers() {
        stateTask?.cancel()
        stateTask = forwardLatest(captionsStatusDataSource.captionsState) { [weak self] state in
            await self?.processNewState(state)
        }

        if let publisher = call?.captionsPublisher {
            captionsTask?.cancel()
            captionsTask = forwardLatest(publisher) { [weak self] captions in
                await self?.captionsRepository.updateCaptions(captions)
            }
        }
    }

    /// Subscribes before returning, so no value sent afterwards is missed, and handles
    /// values one at a time in order. Both publishers emit full snapshots, so only the
    /// newest pending value is kept while `handle` runs.
    private func forwardLatest<Value: Sendable>(
        _ publisher: AnyPublisher<Value, Never>,
        _ handle: @escaping (Value) async -> Void
    ) -> Task<Void, Never> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self, bufferingPolicy: .bufferingNewest(1))
        publisher
            .handleEvents(receiveCancel: { continuation.finish() })
            .sink(
                receiveCompletion: { _ in continuation.finish() },
                receiveValue: { continuation.yield($0) }
            )
            .store(in: &cancellables)
        return Task {
            for await value in stream {
                await handle(value)
            }
        }
    }

    /// Reacts to a captions state change by enabling or disabling captions on the call.
    ///
    /// - Parameter state: The new captions activation state.
    private func processNewState(_ state: CaptionsState) async {
        switch state {
        case .enabled: await call?.enableCaptions()
        case .disabled: await call?.disableCaptions()
        }
    }
}
