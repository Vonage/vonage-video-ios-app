//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import OSLog
import SwiftUI
import UIKit
import VERADomain

/// Coordinates Picture-in-Picture for an active Vonage call.
///
/// Every participant owns a permanent renderer (attached at stream creation, never rewired), so
/// retargeting PiP is a single cheap operation: point the PiP sample-buffer feed at the target's
/// renderer. The AVKit controller itself is anchored once to the room-level
/// ``PictureInPictureAnchorView`` and never re-anchored to tiles: tiles are demolished by layout
/// changes and SwiftUI identity resets, and AVKit silently refuses to start (or permanently drops
/// `isPictureInPicturePossible`) when its source view leaves the window — only the room view is
/// mounted for the whole call. ``PictureInPictureParticipantSelector`` decides *which* participant
/// to follow.
@MainActor
public final class PictureInPictureSessionOrchestrator: ObservableObject {
    private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")

    @Published public private(set) var isInPictureInPicture = false
    @Published public private(set) var canStartPictureInPicture = false
    @Published public private(set) var pipTargetParticipantId: String?

    private let participantSelector = PictureInPictureParticipantSelector()
    private let pipController = PictureInPictureController()

    /// Timestamp of the last in-PiP active-speaker retarget, used to debounce rapid switching when
    /// multiple participants talk over each other.
    private var lastInPipRetargetAt: Date?
    private static let minimumInPipRetargetInterval: TimeInterval = 1.5

    /// The current target's renderer: feeds the PiP window, hosts the camera-off placeholder, and
    /// its view is the controller's anchor.
    private var activePipRenderer: PictureInPictureVideoRenderer?

    /// The source view the controller is currently configured with, to detect when SwiftUI has
    /// replaced the room anchor view instance. Weak: owned by the room hierarchy.
    private weak var lastConfiguredSourceView: UIView?

    private var cancellables = Set<AnyCancellable>()
    private weak var call: VonageCall?
    private var currentPipTargetId: String?
    private var pipTargetCameraEnabled = false
    private var wantsPictureInPicture = false

    public init() {
        pipController.onPictureInPictureStateDidStart = { [weak self] in
            guard let self else { return }
            self.isInPictureInPicture = true
        }
        pipController.onPictureInPictureStateDidStop = { [weak self] in
            guard let self else { return }
            self.isInPictureInPicture = false
            self.wantsPictureInPicture = false
            self.lastInPipRetargetAt = nil
        }
        pipController.onPictureInPicturePossibleDidChange = { [weak self] in
            guard let self else { return }
            self.canStartPictureInPicture = self.pipController.canStartPictureInPicture
            if self.canStartPictureInPicture && self.wantsPictureInPicture {
                self.startPictureInPictureIfPossible()
            }
        }
        pipController.onPictureInPictureFailed = { [weak self] _ in
            self?.wantsPictureInPicture = false
        }
    }

    public func bind(to call: VonageCall) {
        guard self.call == nil else {
            return
        }
        self.call = call

        call.participantsPublisher
            // Drop high-frequency audio-level churn: only react when something that can change the
            // PiP target/placeholder changes (participant set, camera states, active speaker, local
            // camera). Without this, every audio-level emission spawns a @MainActor task and these
            // pile up faster than they drain, starving the main actor (frozen video, dead buttons).
            .removeDuplicates {
                PictureInPictureParticipantSelector.signature(for: $0)
                    == PictureInPictureParticipantSelector.signature(for: $1)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task { @MainActor [weak self] in
                    await self?.updatePipTarget(for: state)
                }
            }
            .store(in: &cancellables)

        call.callState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard state == .disconnected || state == .idle else { return }
                self?.tearDown()
            }
            .store(in: &cancellables)
    }

    /// Registers the room-level anchor and configures the controller against it, making PiP
    /// startable from the moment the room is on screen.
    public func registerAnchor(sourceView: UIView, videoFrame: CGRect) {
        Self.logger.debug("anchor registered \(String(describing: videoFrame.size), privacy: .public)")
        configureController(sourceView: sourceView)
    }

    public func requestPictureInPicture() {
        let message =
            "requestPictureInPicture; target=\(currentPipTargetId ?? "nil") "
            + "canStart=\(pipController.canStartPictureInPicture) configured=\(pipController.isConfigured)"
        Self.logger.debug("\(message, privacy: .public)")
        wantsPictureInPicture = true
        startPictureInPictureIfPossible()

        // AVKit can silently swallow a start issued exactly at the background transition (no
        // didStart, no failedToStart — observed when the camera pipeline is being interrupted at
        // the same moment). One delayed re-attempt while PiP is still wanted covers that window;
        // returning to the foreground clears `wantsPictureInPicture`, so this never fires late.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard let self, self.wantsPictureInPicture, !self.isInPictureInPicture else { return }
            Self.logger.debug("start watchdog; retrying startPictureInPicture")
            self.startPictureInPictureIfPossible()
        }
    }

    private func startPictureInPictureIfPossible() {
        guard currentPipTargetId != nil else {
            Self.logger.debug("start bail; no target")
            return
        }

        guard pipController.canStartPictureInPicture else {
            Self.logger.debug("start bail; controller cannot start yet")
            return
        }
        Self.logger.debug("startPictureInPicture invoked")
        pipController.startPictureInPicture()
    }

    /// Dismisses the PiP window when the app returns to the foreground by a route other than tapping
    /// the PiP window (e.g. the app icon). Tapping the window triggers iOS's own restore flow, but
    /// foregrounding via the icon does not, so without this the window lingers over the full-screen
    /// app. A no-op when PiP is not running.
    public func stopPictureInPicture() {
        Self.logger.debug("stopPictureInPicture; inPiP=\(self.isInPictureInPicture, privacy: .public)")
        wantsPictureInPicture = false
        pipController.stopPictureInPicture()
    }

    public func tearDown() {
        cancellables.removeAll()
        lastInPipRetargetAt = nil
        activePipRenderer?.stopPlaceholder()
        activePipRenderer = nil
        pipController.tearDown()
        participantSelector.reset()
        call = nil
        currentPipTargetId = nil
        pipTargetCameraEnabled = false
        isInPictureInPicture = false
        canStartPictureInPicture = false
        pipTargetParticipantId = nil
        wantsPictureInPicture = false
        lastConfiguredSourceView = nil
    }

    // MARK: - Target selection

    private func updatePipTarget(for state: ParticipantsState) async {
        if isInPictureInPicture || pipController.isInPictureInPicture {
            await updateActivePipTargetWhileInPictureInPicture(for: state)
            return
        }

        let targetId = participantSelector.pipTargetId(for: state)
        let targetCameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(
            participantId: targetId, in: state)
        let targetMessage =
            "updatePipTarget target=\(targetId ?? "nil") "
            + "current=\(currentPipTargetId ?? "nil") cameraOn=\(targetCameraEnabled) "
            + "participants=\(state.participants.count)"
        Self.logger.debug("\(targetMessage, privacy: .public)")

        if targetId == currentPipTargetId {
            syncPlaceholder(cameraEnabled: targetCameraEnabled, targetId: targetId, state: state)
            return
        }

        let currentTargetHasCamera = PictureInPictureParticipantSelector.isCameraEnabled(
            participantId: currentPipTargetId,
            in: state
        )
        if wantsPictureInPicture,
            currentPipTargetId != nil,
            currentTargetHasCamera,
            targetId != currentPipTargetId
        {
            return
        }

        await retargetPipRenderer(to: targetId, state: state)
    }

    /// While PiP is active we follow the active speaker but must not disturb the running PiP
    /// window: retargets move only the sample-buffer feed, and when the target stays put we keep
    /// its placeholder in sync with its camera state.
    private func updateActivePipTargetWhileInPictureInPicture(for state: ParticipantsState) async {
        let targetId = participantSelector.activeSpeakerPipTargetId(for: state, currentPipTargetId: currentPipTargetId)

        if targetId != currentPipTargetId {
            let now = Date()
            if let last = lastInPipRetargetAt,
                now.timeIntervalSince(last) < Self.minimumInPipRetargetInterval
            {
                // Fall through to keep the current target's placeholder in sync.
            } else {
                lastInPipRetargetAt = now
                await retargetPipRenderer(to: targetId, state: state)
                return
            }
        }

        guard let currentPipTargetId else {
            return
        }

        let cameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(
            participantId: currentPipTargetId, in: state)
        syncPlaceholder(cameraEnabled: cameraEnabled, targetId: currentPipTargetId, state: state)
    }

    /// Keeps the camera-off placeholder in step with the target's camera state. The orchestrator
    /// is the single source of truth here: the renderer drops incoming frames while the
    /// placeholder is active, so it is explicitly stopped when the camera is re-enabled — and with
    /// permanent renderers there is nothing to rebuild, frames resume on the existing pipeline.
    private func syncPlaceholder(cameraEnabled: Bool, targetId: String?, state: ParticipantsState) {
        let cameraWasEnabled = pipTargetCameraEnabled
        pipTargetCameraEnabled = cameraEnabled

        guard let activePipRenderer else { return }

        if cameraWasEnabled, !cameraEnabled {
            activePipRenderer.startPlaceholder(name: participantName(for: targetId, in: state))
        } else if !cameraWasEnabled, cameraEnabled {
            activePipRenderer.stopPlaceholder()
        } else if !cameraEnabled {
            activePipRenderer.updatePlaceholderName(participantName(for: targetId, in: state))
        }
    }

    // MARK: - Retargeting

    /// Points the PiP feed and anchor at `targetId`'s permanent renderer.
    ///
    /// Nothing on the OpenTok side is rewired — renderers are attached to their streams for life.
    /// Retargeting moves the sample-buffer feed, re-anchors the controller to the new target's
    /// tile view (deferred to PiP stop while PiP is running — AVKit forbids reconfiguring an
    /// active controller), and keeps the target's video subscription alive while its tile is
    /// hidden.
    private func retargetPipRenderer(to targetId: String?, state: ParticipantsState) async {
        let previousTargetId = currentPipTargetId
        let previousRenderer = activePipRenderer
        Self.logger.debug(
            "retarget \(previousTargetId ?? "nil", privacy: .public) -> \(targetId ?? "nil", privacy: .public)")

        previousRenderer?.stopPlaceholder()
        if let previousTargetId, let call, previousTargetId != call.publisher.id {
            await call.subscriber(for: previousTargetId)?.setPictureInPictureTarget(false)
        }

        // The target is committed only when its renderer is resolved; a failed resolution leaves
        // it unset so the next participant-state emission retries the switch.
        currentPipTargetId = nil
        pipTargetCameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(participantId: targetId, in: state)

        guard let targetId, let call else {
            pipTargetParticipantId = nil
            return
        }

        let renderer: PictureInPictureVideoRenderer?
        if call.publisher.id == targetId {
            renderer = call.publisher.inlineVideoRenderer
        } else if let subscriber = await call.subscriber(for: targetId) {
            subscriber.setPictureInPictureTarget(true)
            renderer = subscriber.inlineVideoRenderer
        } else {
            renderer = nil
        }

        guard let renderer else {
            Self.logger.debug("retarget: no stream for \(targetId, privacy: .public); will retry")
            pipTargetParticipantId = nil
            return
        }

        activePipRenderer = renderer
        currentPipTargetId = targetId
        pipTargetParticipantId = targetId

        if previousRenderer !== renderer {
            previousRenderer?.pipBufferDisplayLayer = nil
        }
        pipController.attachFeed(to: renderer)

        if pipTargetCameraEnabled {
            renderer.stopPlaceholder()
        } else {
            renderer.startPlaceholder(name: participantName(for: targetId, in: state))
        }
    }

    // MARK: - Anchoring

    private func configureController(sourceView: UIView) {
        guard pipController.isPictureInPictureSupported,
            !pipController.isInPictureInPicture,
            !pipController.isConfigured || sourceView !== lastConfiguredSourceView
        else { return }

        pipController.configure(with: sourceView)
        lastConfiguredSourceView = sourceView

        // The feed follows the current target; wire it if a target already exists (the anchor can
        // register before or after the first retarget).
        if let activePipRenderer {
            pipController.attachFeed(to: activePipRenderer)
        }

        canStartPictureInPicture = pipController.canStartPictureInPicture

        if wantsPictureInPicture {
            startPictureInPictureIfPossible()
        }
    }

    private func participantName(for participantId: String?, in state: ParticipantsState) -> String {
        PictureInPictureParticipantSelector.participantName(for: participantId, in: state)
    }
}
