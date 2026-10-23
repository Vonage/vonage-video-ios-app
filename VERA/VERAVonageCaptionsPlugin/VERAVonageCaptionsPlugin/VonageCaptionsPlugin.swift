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
///                       ├─ cancel subscriptions and workers
///                       ├─ await any in-flight write
///                       ├─ disable and reset captions status
///                       └─ clear captionsRepository
/// ```
///
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallHolder``, ``CaptionsStatusDataSource``
@MainActor
public final class VonageCaptionsPlugin: VonagePlugin, VonagePluginCallHolder {
    private var cancellables = Set<AnyCancellable>()
    /// Tracks the caption-forwarding Task so it can be cancelled on call end.
    private var captionsTask: Task<Void, Never>?
    private var activationTask: Task<Void, Never>?
    private var captionsContinuation: AsyncStream<[CaptionItem]>.Continuation?
    private var activationContinuation: AsyncStream<CaptionsState>.Continuation?
    private var lifecycleTask: Task<Void, Never>?

    private enum LifecycleOperation { case start, end }

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

    deinit {
        captionsTask?.cancel()
        activationTask?.cancel()
        lifecycleTask?.cancel()
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
        await enqueueLifecycle(.start)
    }

    /// Called when the call ends and the Vonage session is disconnecting.
    ///
    /// Performs cleanup in order:
    /// 1. Cancels subscriptions and joins pending forwarding and activation work.
    /// 2. Disables captions and resets ``CaptionsStatusDataSource``.
    /// 3. Clears the repository after the final in-flight write completes.
    public func callDidEnd() async throws {
        await enqueueLifecycle(.end)
    }

    // MARK: - Private

    /// Serializes lifecycle calls across suspension points, including a restart during teardown.
    private func enqueueLifecycle(_ operation: LifecycleOperation) async {
        let previous = lifecycleTask
        let activeCall = call
        let task = Task { @MainActor [weak self, weak activeCall] in
            await previous?.value
            guard !Task.isCancelled, let self else { return }
            await self.cancelObservables()
            switch operation {
            case .start:
                self.initObservers(activeCall: activeCall)
            case .end:
                await activeCall?.disableCaptions()
                self.captionsStatusDataSource.reset()
                await self.captionsRepository.updateCaptions([])
            }
        }
        lifecycleTask = task
        await task.value
    }

    /// Stops inputs first, then joins any suspended write before the final clear.
    private func cancelObservables() async {
        cancellables.removeAll()
        captionsContinuation?.finish()
        activationContinuation?.finish()
        captionsContinuation = nil
        activationContinuation = nil
        let captionsTask = captionsTask
        let activationTask = activationTask
        self.captionsTask = nil
        self.activationTask = nil
        captionsTask?.cancel()
        activationTask?.cancel()
        await captionsTask?.value
        await activationTask?.value
    }

    private func initObservers(activeCall: (any CallFacade)?) {
        // Caption arrays describe the full current snapshot. While a write is suspended,
        // retain only the newest pending snapshot instead of growing a transcription backlog.
        let captions = AsyncStream<[CaptionItem]>.makeStream(bufferingPolicy: .bufferingNewest(1))
        captionsContinuation = captions.continuation
        activeCall?.captionsPublisher
            .sink { @Sendable snapshot in captions.continuation.yield(snapshot) }
            .store(in: &cancellables)
        let repository = captionsRepository
        captionsTask = Task {
            for await snapshot in captions.stream {
                guard !Task.isCancelled else { return }
                await repository.updateCaptions(snapshot)
            }
        }

        // Activation commands run sequentially, so a slow enable cannot overtake disable.
        let activation = AsyncStream<CaptionsState>.makeStream()
        activationContinuation = activation.continuation
        captionsStatusDataSource.captionsState
            .sink { @Sendable state in activation.continuation.yield(state) }
            .store(in: &cancellables)
        activationTask = Task { @MainActor [weak activeCall] in
            for await state in activation.stream {
                guard !Task.isCancelled, let activeCall else { return }
                switch state {
                case .enabled: await activeCall.enableCaptions()
                case .disabled: await activeCall.disableCaptions()
                }
            }
        }
    }
}
