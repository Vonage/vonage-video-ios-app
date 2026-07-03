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
/// iOS PiP is anchored to an already-mounted `activeVideoCallSourceView`, not to a separate
/// background-only screen like Android's PiP UI-mode flow. The orchestrator therefore attaches the
/// shared PiP renderer to the participant tile that is already visible in the meeting room before
/// the app backgrounds.
///
/// It owns the AVKit source-view lifecycle and the published UI state, and delegates the two other
/// concerns: ``PictureInPictureParticipantSelector`` decides *which* participant to follow, and
/// ``PictureInPictureRenderRouter`` moves the renderers so tiles stay alive as the target changes.
@MainActor
public final class PictureInPictureSessionOrchestrator: ObservableObject {
    private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")

    @Published public private(set) var isInPictureInPicture = false
    @Published public private(set) var canStartPictureInPicture = false
    @Published public private(set) var pipTargetParticipantId: String?

    private let participantSelector = PictureInPictureParticipantSelector()
    private let renderRouter = PictureInPictureRenderRouter()

    /// Timestamp of the last in-PiP active-speaker retarget, used to debounce rapid switching when
    /// multiple participants talk over each other.
    private var lastInPipRetargetAt: Date?
    private static let minimumInPipRetargetInterval: TimeInterval = 1.5

    /// Tracks the last source view we successfully (re)configured `pipController` with so we can
    /// detect when SwiftUI has replaced the underlying `PictureInPictureVideoContainerView` (e.g.
    /// after a participant grid reflow). The view is held weakly because its lifetime is owned by
    /// the meeting room view hierarchy.
    private weak var lastConfiguredSourceView: UIView?
    private weak var pendingSourceView: UIView?
    private var pendingVideoFrame: CGRect = .zero
    private let pipController = PictureInPictureController()
    private var cancellables = Set<AnyCancellable>()
    private weak var call: VonageCall?
    private var currentPipTargetId: String?
    private var pipTargetCameraEnabled = false
    private var wantsPictureInPicture = false
    private var cachedInlineView: AnyView?
    private var pipConfigurationToken = UUID()

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
            self.reconfigureForPendingSourceViewIfNeeded()
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

    /// Inline video surface for the PiP target — shown in the participant tile and used as the PiP source.
    public func makeInlineVideoView() -> AnyView {
        if let cachedInlineView {
            return cachedInlineView
        }

        let inlineView = AnyView(
            PictureInPictureInlineVideoView(
                renderer: renderRouter.videoRenderer,
                configurationToken: pipConfigurationToken
            ) { [weak self] view, frame in
                self?.configurePictureInPicture(sourceView: view, videoFrame: frame)
            }
        )
        cachedInlineView = inlineView
        return inlineView
    }

    public func configurePictureInPicture(sourceView: UIView, videoFrame: CGRect) {
        guard pipController.isPictureInPictureSupported else {
            return
        }
        guard videoFrame.width > 1, videoFrame.height > 1 else {
            return
        }

        pendingSourceView = sourceView
        pendingVideoFrame = videoFrame
        do {
            try pipController.configureIfNeeded(
                with: sourceView,
                videoRenderer: renderRouter.activePipRenderer,
                videoFrame: videoFrame
            )
            lastConfiguredSourceView = sourceView
            Self.logger.debug(
                "configure ok; canStart=\(self.pipController.canStartPictureInPicture, privacy: .public)")
        } catch {
            let sourceViewChanged = sourceView !== lastConfiguredSourceView
            if pipController.isConfigured,
                !pipController.isInPictureInPicture,
                sourceViewChanged
            {
                tryReconfiguration(sourceView: sourceView, videoFrame: videoFrame)
            } else if pipController.isConfigured,
                pipTargetCameraEnabled,
                wantsPictureInPicture || renderRouter.activePipRenderer.renderedFrameCount > 0
            {
                tryReconfiguration(sourceView: sourceView, videoFrame: videoFrame)
            } else {
                return
            }
        }

        canStartPictureInPicture = pipController.canStartPictureInPicture

        if wantsPictureInPicture {
            startPictureInPictureIfPossible()
        }
    }

    private func tryReconfiguration(sourceView: UIView, videoFrame: CGRect) {
        do {
            try pipController.reconfigure(
                with: sourceView,
                videoRenderer: renderRouter.activePipRenderer,
                videoFrame: videoFrame
            )
            lastConfiguredSourceView = sourceView
        } catch {
            Self.logger.error("\(error.localizedDescription)")
        }
    }

    private func reconfigureForPendingSourceViewIfNeeded() {
        guard let pendingSourceView,
            pendingSourceView !== lastConfiguredSourceView,
            pendingVideoFrame.width > 1,
            pendingVideoFrame.height > 1,
            pipController.isConfigured,
            !pipController.isInPictureInPicture
        else { return }

        do {
            try pipController.reconfigure(
                with: pendingSourceView,
                videoRenderer: renderRouter.activePipRenderer,
                videoFrame: pendingVideoFrame
            )
            lastConfiguredSourceView = pendingSourceView
            canStartPictureInPicture = pipController.canStartPictureInPicture
        } catch {
            Self.logger.error("\(error.localizedDescription)")
        }
    }

    public func requestPictureInPicture() {
        let message =
            "requestPictureInPicture; target=\(currentPipTargetId ?? "nil") "
            + "canStart=\(pipController.canStartPictureInPicture) configured=\(pipController.isConfigured)"
        Self.logger.debug("\(message, privacy: .public)")
        wantsPictureInPicture = true
        startPictureInPictureIfPossible()
    }

    public func startPictureInPictureIfPossible() {
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
        renderRouter.reset()
        pipController.tearDown()
        participantSelector.reset()
        call = nil
        currentPipTargetId = nil
        pipTargetCameraEnabled = false
        isInPictureInPicture = false
        canStartPictureInPicture = false
        pipTargetParticipantId = nil
        wantsPictureInPicture = false
        cachedInlineView = nil
        lastConfiguredSourceView = nil
        pendingSourceView = nil
        pendingVideoFrame = .zero
    }

    private func updatePipTarget(for state: ParticipantsState) async {
        renderRouter.pruneSubscriberPreviewRenderers(keeping: Set(state.participants.map(\.id)))

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
            let cameraWasEnabled = pipTargetCameraEnabled
            pipTargetCameraEnabled = targetCameraEnabled

            if cameraWasEnabled && !targetCameraEnabled {
                renderRouter.activePipRenderer.startPlaceholder(name: participantName(for: targetId, in: state))
                canStartPictureInPicture = pipController.canStartPictureInPicture
                return
            }

            if !cameraWasEnabled && targetCameraEnabled, let targetId {
                renderRouter.activePipRenderer.stopPlaceholder()
                await refreshPipPipeline(targetId: targetId, state: state)
                return
            }

            if !targetCameraEnabled {
                renderRouter.activePipRenderer.updatePlaceholderName(participantName(for: targetId, in: state))
            }
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

        await switchPipTarget(to: targetId, state: state)
    }

    /// While PiP is active we follow the active speaker but must not tear down the running PiP
    /// controller. When the active speaker changes we re-point the shared renderer at the new
    /// participant (lightweight retarget, keeping the controller and its sample-buffer layer), and
    /// when the current target stays put we only keep its placeholder in sync with its camera state.
    /// The orchestrator is the single source of truth for the placeholder here: the renderer drops
    /// incoming frames while the placeholder is active, so we explicitly stop it when the camera is
    /// re-enabled to let live video resume.
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
                await retargetPipRenderer(to: targetId, state: state, reconfigureController: false)
                return
            }
        }

        guard let currentPipTargetId else {
            return
        }

        let cameraWasEnabled = pipTargetCameraEnabled
        let cameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(
            participantId: currentPipTargetId, in: state)
        pipTargetCameraEnabled = cameraEnabled

        if cameraWasEnabled, !cameraEnabled {
            renderRouter.activePipRenderer.startPlaceholder(name: participantName(for: currentPipTargetId, in: state))
        } else if !cameraWasEnabled, cameraEnabled {
            renderRouter.activePipRenderer.stopPlaceholder()
        } else if !cameraEnabled {
            renderRouter.activePipRenderer.updatePlaceholderName(participantName(for: currentPipTargetId, in: state))
        }
    }

    private func switchPipTarget(to targetId: String?, state: ParticipantsState) async {
        await retargetPipRenderer(to: targetId, state: state, reconfigureController: true)
    }

    /// Points the shared renderer at `targetId`, detaching it from the previous target.
    ///
    /// - Parameter reconfigureController: when `true` (not in PiP) the PiP controller and its
    ///   sample-buffer layer are torn down and rebuilt for the new target. When `false` (active
    ///   speaker change *while in PiP*) the running controller and its buffer layer are preserved —
    ///   only the renderer's stream source changes — so PiP keeps playing without interruption.
    private func retargetPipRenderer(
        to targetId: String?,
        state: ParticipantsState,
        reconfigureController: Bool
    ) async {
        let previousTargetId = currentPipTargetId
        let previousRenderer = renderRouter.activePipRenderer
        let retargetMessage =
            "retarget \(previousTargetId ?? "nil") -> \(targetId ?? "nil") "
            + "reconfigureController=\(reconfigureController)"
        Self.logger.debug("\(retargetMessage, privacy: .public)")

        if reconfigureController {
            invalidatePipConfiguration()
        } else {
            // Keep the controller/buffer layer; just stop the previous target's placeholder.
            previousRenderer.stopPlaceholder()
        }

        await renderRouter.clearTarget(previousTargetId, call: call)

        currentPipTargetId = targetId
        pipTargetParticipantId = nil
        pipTargetCameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(participantId: targetId, in: state)

        guard let targetId, let call else {
            return
        }

        await applyPipRenderer(to: targetId, call: call)

        // While PiP keeps running, the sample-buffer layer must follow the active renderer when the
        // target moved between the publisher's permanent renderer and the shared remote renderer.
        if !reconfigureController, renderRouter.activePipRenderer !== previousRenderer {
            previousRenderer.pipBufferDisplayLayer = nil
            pipController.attachFeed(to: renderRouter.activePipRenderer)
        }

        if pipTargetCameraEnabled {
            renderRouter.activePipRenderer.stopPlaceholder()
        } else {
            renderRouter.activePipRenderer.startPlaceholder(name: participantName(for: targetId, in: state))
        }
    }

    /// The current target's camera came back on. The publisher's permanent renderer resumes on its
    /// own (its pipeline is never rewired), so only remote targets rebuild their attachment. The
    /// controller is kept alive in both cases so `canStartPictureInPicture` survives camera flaps.
    private func refreshPipPipeline(targetId: String, state: ParticipantsState) async {
        pipTargetCameraEnabled = PictureInPictureParticipantSelector.isCameraEnabled(participantId: targetId, in: state)

        guard let call else { return }
        if call.publisher.id == targetId {
            return
        }

        invalidatePipConfiguration()
        await applyPipRenderer(to: targetId, call: call, forceReattach: true)
    }

    private func applyPipRenderer(
        to targetId: String,
        call: VonageCall,
        forceReattach: Bool = false
    ) async {
        do {
            try await renderRouter.applyRenderer(
                to: targetId,
                call: call,
                inlineView: { makeInlineVideoView() },
                forceReattach: forceReattach
            )
            Self.logger.debug("applyPipRenderer attached target=\(targetId, privacy: .public)")
        } catch {
            // No stream for this target yet (e.g. subscriber not created): leave target state as-is;
            // the next participant-state emission retries once the stream exists.
            Self.logger.debug("applyPipRenderer no stream for \(targetId, privacy: .public)")
            return
        }

        currentPipTargetId = targetId
        pipTargetParticipantId = targetId

        // The publisher's renderer is embedded in the tile directly (no SwiftUI inline wrapper), so
        // it reports source-view readiness itself; configure PiP from it as soon as it is on screen.
        if call.publisher.id == targetId {
            let renderer = renderRouter.activePipRenderer
            renderer.onSourceViewReady = { [weak self] view, frame in
                self?.configurePictureInPicture(sourceView: view, videoFrame: frame)
            }
            renderer.notifySourceViewReadyIfEligible()
        }
    }

    private func invalidatePipConfiguration() {
        renderRouter.activePipRenderer.stopPlaceholder()
        renderRouter.activePipRenderer.prepareForPipRefresh()
        renderRouter.activePipRenderer.resetSourceViewReadyNotification()
        pipController.tearDown()
        canStartPictureInPicture = false
        cachedInlineView = nil
        pipConfigurationToken = UUID()
        lastConfiguredSourceView = nil
    }

    private func participantName(for participantId: String?, in state: ParticipantsState) -> String {
        PictureInPictureParticipantSelector.participantName(for: participantId, in: state)
    }
}
