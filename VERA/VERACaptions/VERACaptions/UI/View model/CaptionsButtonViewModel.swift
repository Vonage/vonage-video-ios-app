//
//  Created by Vonage on 6/2/26.
//

import Combine
import Foundation
import VERADomain

/// View model that drives the captions toggle button.
///
/// `CaptionsButtonViewModel` manages the enable / disable lifecycle for
/// live captions during a call:
///
/// 1. **State observation** – subscribes to ``CaptionsStatusDataSource/captionsState``
///    and publishes the current ``CaptionsState`` so that ``CaptionsButtonContainer``
///    can render the correct icon.
/// 2. **Tap handling** – ``onTap()`` toggles captions by invoking either
///    ``EnableCaptionsUseCase`` or ``DisableCaptionsUseCase``. If enabling
///    fails, a failure ``ToastItem`` is published for the host view to display.
///
/// ## Setup
///
/// Call ``setup()`` once (typically in `.onAppear`) to start the status
/// subscription. The method is guarded so subsequent calls are no-ops.
///
/// ```swift
/// let vm = CaptionsButtonViewModel(…)
/// vm.setup()          // starts observing captions state
/// vm.onTap()          // toggles captions on / off
/// ```
///
/// - SeeAlso: ``CaptionsButtonContainer``, ``CaptionsButton``, ``CaptionsFactory``
public final class CaptionsButtonViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    /// The current captions activation state, observed by the button view.
    @Published public var state: CaptionsState = .disabled

    /// An optional toast shown when enabling captions fails.
    ///
    /// The host view (e.g. `MeetingRoomView`) should observe this property
    /// and present the toast to the user.
    @Published public var toast: ToastItem?

    /// The room name passed to ``EnableCaptionsUseCase`` when activating captions.
    private let roomName: RoomName
    /// Use case responsible for enabling captions via the backend.
    private let enableCaptionsUseCase: EnableCaptionsUseCase
    /// Use case responsible for disabling captions locally.
    private let disableCaptionsUseCase: DisableCaptionsUseCase
    /// Reactive source of the current captions activation state.
    private let captionsStatusDataSource: CaptionsStatusDataSource
    /// Guard flag ensuring ``setup()`` only subscribes once.
    private var initiated = false

    /// Creates a new button view model.
    ///
    /// - Parameters:
    ///   - roomName: The name of the active room, forwarded when enabling captions.
    ///   - enableCaptionsUseCase: The use case that activates captions on the backend.
    ///   - disableCaptionsUseCase: The use case that deactivates captions locally.
    ///   - captionsStatusDataSource: The data source that publishes activation state changes.
    public init(
        roomName: RoomName,
        enableCaptionsUseCase: EnableCaptionsUseCase,
        disableCaptionsUseCase: DisableCaptionsUseCase,
        captionsStatusDataSource: CaptionsStatusDataSource
    ) {
        self.roomName = roomName
        self.enableCaptionsUseCase = enableCaptionsUseCase
        self.disableCaptionsUseCase = disableCaptionsUseCase
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    /// Starts observing the captions status data source.
    ///
    /// Subscribes to ``CaptionsStatusDataSource/captionsState`` and updates
    /// ``state`` on the main queue. This method is idempotent — calling it
    /// more than once has no effect.
    public func setup() {
        guard !initiated else { return }
        initiated = true

        captionsStatusDataSource.captionsState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.state = status
            }
            .store(in: &cancellables)
    }

    /// Handles a user tap on the captions button.
    ///
    /// - When captions are **enabled**, immediately calls ``DisableCaptionsUseCase``
    ///   to deactivate them.
    /// - When captions are **disabled**, asynchronously calls ``EnableCaptionsUseCase``.
    ///   On failure, publishes a ``ToastItem`` with a localised error message.
    public func onTap() {
        switch state {
        case .enabled(_):
            disableCaptionsUseCase()
        case .disabled:
            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await enableCaptionsUseCase(.init(roomName: roomName))
                } catch {
                    self.toast = .init(
                        message: String(localized: "captions_enable_error", bundle: .veraCaptions),
                        mode: .failure
                    )
                }
            }
        }
    }
}
