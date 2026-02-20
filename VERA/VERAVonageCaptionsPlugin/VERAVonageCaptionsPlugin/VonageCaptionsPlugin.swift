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
        captionsStatusDataSource.reset()
        await captionsRepository.updateCaptions([])
        cancellables.removeAll()
    }

    /// Creates the two Combine pipelines that power this plugin.
    private func initObservers() {
        captionsStatusDataSource.captionsState
            .sink { [weak self] state in
                self?.processNewState(state)
            }
            .store(in: &cancellables)

        call?.captionsPublisher
            .sink { [weak self] captions in
                guard let self else { return }
                Task { await self.captionsRepository.updateCaptions(captions) }
            }
            .store(in: &cancellables)
    }

    /// Reacts to a captions state change by enabling or disabling captions on the call.
    ///
    /// - Parameter state: The new captions activation state.
    private func processNewState(_ state: CaptionsState) {
        Task {
            switch state {
            case .enabled: await call?.enableCaptions()
            case .disabled: await call?.disableCaptions()
            }
        }
    }
}
