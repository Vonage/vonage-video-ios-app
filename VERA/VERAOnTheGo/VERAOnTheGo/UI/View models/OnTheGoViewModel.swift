//
//  Created by Vonage on 17/10/26.
//

import Combine
import Foundation
import Observation

#if canImport(UIKit)
    import UIKit
#endif

/// State machine driving the On-the-Go audio-first call mode.
///
/// The host pushes call state in via ``update(snapshot:)`` and provides
/// ``OnTheGoCallActions`` closures for anything the view model needs to do to
/// the call. Mic/camera state always comes back through the snapshot — the
/// view model never mirrors it locally.
///
/// Suggestion rules:
/// - Motion detection runs only while *all* gating conditions hold
///   (see ``shouldDetectMotion``).
/// - Once suggested, the banner auto-declines after
///   ``OnTheGoConfiguration/suggestionTimeout``.
/// - On entry the camera is turned off and the mic is auto-muted; on exit the
///   camera is restored only if it was on at entry and is still off.
@MainActor
@Observable
public final class OnTheGoViewModel {

    // MARK: - Observable state

    /// Current state of the On-the-Go flow.
    public private(set) var state: OnTheGoState = .idle

    /// Latest call snapshot pushed by the host.
    public private(set) var snapshot: OnTheGoCallSnapshot = .disconnected

    /// Whether the shared-content sheet is presented.
    public private(set) var isSharedContentPresented = false

    /// Whether the suggestion banner has been declined/suppressed for the
    /// current call. Resets when a new call connects.
    public private(set) var isSuggestionSuppressedForThisCall = false

    /// Integrator-provided configuration.
    public let configuration: OnTheGoConfiguration

    /// Whether motion & fitness access was denied or is restricted, so the
    /// settings row can show a warning.
    public var isMotionPermissionDenied: Bool {
        guard let motionProvider else { return false }
        return [.denied, .restricted].contains(motionProvider.authorizationStatus)
    }

    // MARK: - Dependencies

    private let preferences: OnTheGoPreferencesRepository
    private let motionProvider: MotionActivityProviding?
    private let detector: OnTheGoMotionDetector
    private let actions: OnTheGoCallActions
    private let scheduleTimeout: @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> AnyCancellable

    // MARK: - Private state

    private var timeoutCancellable: AnyCancellable?
    private var preferencesCancellable: AnyCancellable?
    private var isMotionDetectionRunning = false
    private var cameraWasEnabledOnEntry = false

    /// Whether motion detection should currently run.
    private var shouldDetectMotion: Bool {
        configuration.isEnabled
            && configuration.autoSuggest
            && preferences.suggestWhenMoving
            && snapshot.isConnected
            && state == .idle
            && !isSuggestionSuppressedForThisCall
            && motionProvider?.isAvailable == true
    }

    // MARK: - Init

    /// Default timeout scheduler backed by `Task.sleep`.
    public static func defaultTimeoutScheduler(
        _ interval: TimeInterval,
        _ work: @escaping @MainActor () -> Void
    ) -> AnyCancellable {
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            work()
        }
        return AnyCancellable { task.cancel() }
    }

    public init(
        configuration: OnTheGoConfiguration,
        preferences: OnTheGoPreferencesRepository,
        motionProvider: MotionActivityProviding?,
        detector: OnTheGoMotionDetector? = nil,
        actions: OnTheGoCallActions,
        scheduleTimeout: (@MainActor (TimeInterval, @escaping @MainActor () -> Void) -> AnyCancellable)? = nil
    ) {
        self.configuration = configuration
        self.preferences = preferences
        self.motionProvider = motionProvider
        let detector = detector ?? OnTheGoMotionDetector()
        self.detector = detector
        self.actions = actions
        // Applied in the body: default arguments are nonisolated, so they
        // cannot reference this main-actor scheduler.
        self.scheduleTimeout = scheduleTimeout ?? Self.defaultTimeoutScheduler

        detector.onSustainedMotion = { [weak self] in
            self?.handleSustainedMotion()
        }

        // The repository emits on the main actor, synchronously. Stay on that
        // turn so a preference change stops detection before the setter returns.
        preferencesCancellable = preferences.suggestWhenMovingPublisher
            .sink { [weak self] _ in
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        self?.reevaluateMotionDetection()
                    }
                } else {
                    Task { @MainActor in
                        self?.reevaluateMotionDetection()
                    }
                }
            }
    }

    // MARK: - Snapshot updates

    /// Called by the host on every call-state change.
    public func update(snapshot: OnTheGoCallSnapshot) {
        let wasConnected = self.snapshot.isConnected
        self.snapshot = snapshot

        if wasConnected, !snapshot.isConnected {
            handleDisconnect()
        } else if !wasConnected, snapshot.isConnected {
            // New call: a fresh suggestion may be offered.
            isSuggestionSuppressedForThisCall = false
        }

        if isSharedContentPresented, snapshot.screenShareParticipant == nil {
            isSharedContentPresented = false
        }

        reevaluateMotionDetection()
    }

    // MARK: - User actions

    /// Enters On-the-Go mode without a suggestion (e.g. from the more menu).
    /// Works even when `autoSuggest` is off or the suggestion was declined.
    public func enterManually() {
        enter()
    }

    /// Accepts the suggestion banner.
    public func acceptSuggestion() {
        enter()
    }

    /// Dismisses the suggestion banner ("Not now"). Suppresses further
    /// suggestions for this call.
    public func declineSuggestion() {
        cancelTimeout()
        state = .idle
        isSuggestionSuppressedForThisCall = true
        reevaluateMotionDetection()
    }

    /// Leaves On-the-Go mode and returns to the normal call UI.
    ///
    /// Restores the camera only if it was on at entry and is still off — if the
    /// user turned it on from elsewhere while active, it stays on. The mic is
    /// never touched.
    public func exit() {
        guard state == .active else { return }
        if cameraWasEnabledOnEntry, !snapshot.isCameraEnabled {
            actions.toggleCamera()
        }
        cameraWasEnabledOnEntry = false
        isSharedContentPresented = false
        state = .idle
        isSuggestionSuppressedForThisCall = true
        reevaluateMotionDetection()
    }

    /// Toggles the microphone through the host action.
    public func toggleMic() {
        #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        actions.toggleMic()
    }

    /// Shows the shared-content sheet, when a screen share exists.
    public func presentSharedContent() {
        guard snapshot.screenShareParticipant != nil else { return }
        isSharedContentPresented = true
    }

    /// Dismisses the shared-content sheet.
    public func dismissSharedContent() {
        isSharedContentPresented = false
    }

    /// Leaves the call.
    public func leaveCall() {
        actions.endCall()
    }

    // MARK: - Private

    private func handleSustainedMotion() {
        // Camera already off means the user is effectively audio-only; there is
        // nothing to gain from the suggestion.
        guard shouldDetectMotion, snapshot.isCameraEnabled else { return }
        detector.reset()
        state = .suggested
        timeoutCancellable = scheduleTimeout(configuration.suggestionTimeout) { [weak self] in
            self?.declineSuggestion()
        }
        reevaluateMotionDetection()
    }

    private func enter() {
        guard snapshot.isConnected else { return }
        cancelTimeout()
        cameraWasEnabledOnEntry = snapshot.isCameraEnabled
        if snapshot.isCameraEnabled {
            actions.toggleCamera()
        }
        if snapshot.isMicEnabled {
            actions.toggleMic()
        }
        state = .active
        reevaluateMotionDetection()
    }

    private func handleDisconnect() {
        cancelTimeout()
        detector.reset()
        cameraWasEnabledOnEntry = false
        isSharedContentPresented = false
        isSuggestionSuppressedForThisCall = false
        state = .idle
    }

    private func reevaluateMotionDetection() {
        if shouldDetectMotion, !isMotionDetectionRunning {
            isMotionDetectionRunning = true
            motionProvider?.start { [weak self] sample in
                self?.detector.ingest(sample)
            }
        } else if !shouldDetectMotion, isMotionDetectionRunning {
            isMotionDetectionRunning = false
            detector.reset()
            motionProvider?.stop()
        }
    }

    private func cancelTimeout() {
        timeoutCancellable?.cancel()
        timeoutCancellable = nil
    }
}
