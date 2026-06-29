//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import SwiftUI
import UIKit
import VERADomain

/// Coordinates Picture-in-Picture for an active Vonage call.
///
/// iOS PiP is anchored to an already-mounted `activeVideoCallSourceView`, not to a separate
/// background-only screen like Android's PiP UI-mode flow. The manager therefore attaches the
/// shared PiP renderer to the participant tile that is already visible in the meeting room before
/// the app backgrounds. Preview renderers keep tiles alive when the shared renderer moves to a new
/// active speaker because OpenTok's default views do not reliably recover after `videoRender` has
/// been replaced.
@MainActor
public final class PictureInPictureManager: ObservableObject {
    @Published public private(set) var isInPictureInPicture = false
    @Published public private(set) var canStartPictureInPicture = false
    @Published public private(set) var pipTargetParticipantId: String?

    let videoRenderer = PictureInPictureVideoRenderer()

    /// Dedicated renderer that keeps the local tile alive when the publisher stops being the PiP
    /// target (the shared `videoRenderer` moves to the remote target in that case).
    private let publisherPreviewRenderer = PictureInPictureVideoRenderer()

    /// Per-remote renderers that keep each remote tile alive after the shared `videoRenderer` moves
    /// to another participant (active-speaker switching). Like the publisher, an `OTSubscriber`'s
    /// default view cannot be revived after a custom `videoRender` was attached.
    private var subscriberPreviewRenderers: [String: PictureInPictureVideoRenderer] = [:]

    /// Timestamp of the last in-PiP active-speaker retarget, used to debounce rapid switching when
    /// multiple participants talk over each other.
    private var lastInPipRetargetAt: Date?
    private static let minimumInPipRetargetInterval: TimeInterval = 1.5

    private let pipController = PictureInPictureController()
    private var cancellables = Set<AnyCancellable>()
    private weak var call: VonageCall?
    private var currentPipTargetId: String?
    private var stickyPipTargetId: String?
    private var pipTargetCameraEnabled = false
    private var wantsPictureInPicture = false
    private var cachedInlineView: AnyView?
    private var pipConfigurationToken = UUID()

    public init() {
        pipController.onPictureInPictureStateDidChange = { [weak self] isActive in
            guard let self else { return }
            self.isInPictureInPicture = isActive
            if !isActive {
                self.wantsPictureInPicture = false
                self.lastInPipRetargetAt = nil
            }
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
            .removeDuplicates { Self.pipSignature(for: $0) == Self.pipSignature(for: $1) }
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
                renderer: videoRenderer,
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

        let configured = pipController.configureIfNeeded(
            with: sourceView,
            videoRenderer: videoRenderer,
            videoFrame: videoFrame
        )

        if !configured {
            if pipController.isConfigured,
                pipTargetCameraEnabled,
                wantsPictureInPicture || videoRenderer.renderedFrameCount > 0
            {
                _ = pipController.reconfigure(
                    with: sourceView,
                    videoRenderer: videoRenderer,
                    videoFrame: videoFrame
                )
            } else {
                return
            }
        }

        canStartPictureInPicture = pipController.canStartPictureInPicture

        if wantsPictureInPicture {
            startPictureInPictureIfPossible()
        }
    }

    public func requestPictureInPicture() {
        wantsPictureInPicture = true
        startPictureInPictureIfPossible()
    }

    public func startPictureInPictureIfPossible() {
        guard currentPipTargetId != nil else {
            return
        }

        guard pipController.canStartPictureInPicture else {
            return
        }
        pipController.startPictureInPicture()
    }

    public func tearDown() {
        cancellables.removeAll()
        videoRenderer.stopPlaceholder()
        subscriberPreviewRenderers.removeAll()
        lastInPipRetargetAt = nil
        if let currentPipTargetId, call?.publisher.id == currentPipTargetId {
            call?.publisher.restoreDefaultVideoView()
        }
        pipController.tearDown()
        call = nil
        currentPipTargetId = nil
        stickyPipTargetId = nil
        pipTargetCameraEnabled = false
        isInPictureInPicture = false
        canStartPictureInPicture = false
        pipTargetParticipantId = nil
        wantsPictureInPicture = false
        cachedInlineView = nil
    }

    private func updatePipTarget(for state: ParticipantsState) async {
        pruneSubscriberPreviewRenderers(keeping: Set(state.participants.map(\.id)))

        if isInPictureInPicture || pipController.isInPictureInPicture {
            await updateActivePipTargetWhileInPictureInPicture(for: state)
            return
        }

        let targetId = pipTargetId(for: state)
        let targetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        if targetId == currentPipTargetId {
            let cameraWasEnabled = pipTargetCameraEnabled
            pipTargetCameraEnabled = targetCameraEnabled

            if cameraWasEnabled && !targetCameraEnabled {
                videoRenderer.startPlaceholder(name: participantName(for: targetId, in: state))
                canStartPictureInPicture = pipController.canStartPictureInPicture
                return
            }

            if !cameraWasEnabled && targetCameraEnabled, let targetId {
                videoRenderer.stopPlaceholder()
                await refreshPipPipeline(targetId: targetId, state: state)
                return
            }

            if !targetCameraEnabled {
                videoRenderer.updatePlaceholderName(participantName(for: targetId, in: state))
            }
            return
        }

        let currentTargetHasCamera = isCameraEnabled(participantId: currentPipTargetId, in: state)
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
    /// The manager is the single source of truth for the placeholder here: the renderer drops
    /// incoming frames while the placeholder is active, so we explicitly stop it when the camera is
    /// re-enabled to let live video resume.
    private func updateActivePipTargetWhileInPictureInPicture(for state: ParticipantsState) async {
        let targetId = activeSpeakerPipTargetId(for: state)

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
        let cameraEnabled = isCameraEnabled(participantId: currentPipTargetId, in: state)
        pipTargetCameraEnabled = cameraEnabled

        if cameraWasEnabled, !cameraEnabled {
            videoRenderer.startPlaceholder(name: participantName(for: currentPipTargetId, in: state))
        } else if !cameraWasEnabled, cameraEnabled {
            videoRenderer.stopPlaceholder()
        } else if !cameraEnabled {
            videoRenderer.updatePlaceholderName(participantName(for: currentPipTargetId, in: state))
        }

    }

    /// PiP target while Picture-in-Picture is active: follow the detected active speaker.
    ///
    /// Falls back to the current target when there is no active speaker (avoids thrashing back to
    /// the sticky default when everyone goes quiet), and finally to the standard sticky selection.
    private func activeSpeakerPipTargetId(for state: ParticipantsState) -> String? {
        if let activeId = state.activeParticipantId,
            state.participants.contains(where: { $0.id == activeId && !$0.isScreenshare })
        {
            return activeId
        }

        if let currentPipTargetId,
            currentPipTargetId == state.localParticipant?.id
                || state.participants.contains(where: { $0.id == currentPipTargetId })
        {
            return currentPipTargetId
        }

        return pipTargetId(for: state)
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

        if reconfigureController {
            invalidatePipConfiguration()
        } else {
            // Keep the controller/buffer layer; just stop the previous target's placeholder.
            videoRenderer.stopPlaceholder()
        }

        // When the publisher stops being the PiP target, hand its tile straight to the dedicated
        // preview renderer with a single `videoRender` reassignment. We deliberately skip
        // clearCurrentPipTarget()'s restoreDefaultVideoView() here: setting OTPublisher.videoRender
        // to nil and immediately reassigning it can leave the publisher not delivering frames to
        // the new renderer, freezing the local self-view.
        if let call,
            previousTargetId == call.publisher.id,
            let newTargetId = targetId,
            newTargetId != call.publisher.id
        {
            call.publisher.applyInlinePreviewRenderer(publisherPreviewRenderer)
        } else {
            await clearCurrentPipTarget()
        }

        currentPipTargetId = targetId
        pipTargetParticipantId = nil
        pipTargetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        guard let targetId, let call else {
            return
        }

        await applyPipRenderer(to: targetId, call: call)
        if pipTargetCameraEnabled {
            videoRenderer.stopPlaceholder()
        } else {
            videoRenderer.startPlaceholder(name: participantName(for: targetId, in: state))
        }
    }

    private func refreshPipPipeline(targetId: String, state: ParticipantsState) async {
        invalidatePipConfiguration()
        pipTargetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        guard let call else { return }
        await applyPipRenderer(to: targetId, call: call, forceReattach: true)
    }

    private func applyPipRenderer(
        to targetId: String,
        call: VonageCall,
        forceReattach: Bool = false
    ) async {
        let inlineView = makeInlineVideoView()

        if call.publisher.id == targetId {
            if forceReattach {
                call.publisher.restoreDefaultVideoView()
            }
            call.publisher.applyPictureInPictureRenderer(videoRenderer, inlineView: inlineView)
        } else if let subscriber = await call.subscriber(for: targetId) {
            if forceReattach {
                subscriber.clearPictureInPictureRenderer()
            }
            subscriber.applyPictureInPictureRenderer(videoRenderer, inlineView: inlineView)
        } else {
            return
        }

        currentPipTargetId = targetId
        pipTargetParticipantId = targetId
    }

    private func invalidatePipConfiguration() {
        videoRenderer.stopPlaceholder()
        videoRenderer.prepareForPipRefresh()
        pipController.tearDown()
        canStartPictureInPicture = false
        cachedInlineView = nil
        pipConfigurationToken = UUID()
    }

    /// Prefers the first joined remote; falls back to any remote with camera when the first has video off.
    /// When there are no remote participants, falls back to the local participant so PiP works solo.
    private func pipTargetId(for state: ParticipantsState) -> String? {
        let remoteParticipants = sortedRemoteParticipants(in: state)
        guard !remoteParticipants.isEmpty else {
            stickyPipTargetId = nil
            return state.localParticipant?.id
        }

        if stickyPipTargetId == nil || !remoteParticipants.contains(where: { $0.id == stickyPipTargetId }) {
            stickyPipTargetId = remoteParticipants.first?.id
        }

        guard let stickyPipTargetId,
            let stickyParticipant = remoteParticipants.first(where: { $0.id == stickyPipTargetId })
        else {
            return remoteParticipants.first?.id
        }

        if stickyParticipant.isCameraEnabled {
            return stickyParticipant.id
        }

        return remoteParticipants.first(where: { $0.isCameraEnabled })?.id ?? stickyParticipant.id
    }

    private func sortedRemoteParticipants(in state: ParticipantsState) -> [Participant] {
        state.participants
            .filter { !$0.isScreenshare }
            .sorted { $0.creationTime < $1.creationTime }
    }

    private func participantName(for participantId: String?, in state: ParticipantsState) -> String {
        guard let participantId else { return "" }

        if state.localParticipant?.id == participantId {
            return state.localParticipant?.name ?? ""
        }

        return state.participants.first(where: { $0.id == participantId })?.name ?? ""
    }

    private func isCameraEnabled(participantId: String?, in state: ParticipantsState) -> Bool {
        guard let participantId else { return false }

        if state.localParticipant?.id == participantId {
            return state.localParticipant?.isCameraEnabled == true
        }

        return state.participants.first(where: { $0.id == participantId })?.isCameraEnabled == true
    }

    private func clearCurrentPipTarget() async {
        guard let currentPipTargetId, let call else { return }

        if call.publisher.id == currentPipTargetId {
            call.publisher.restoreDefaultVideoView()
        } else {
            // Keep the remote tile alive via its dedicated preview renderer: an OTSubscriber's
            // default view can't be revived after a custom videoRender, so reverting to it would
            // leave a gray tile when this participant stops being the PiP/active-speaker target.
            let previewRenderer = subscriberPreviewRenderer(for: currentPipTargetId)
            if let subscriber = await call.subscriber(for: currentPipTargetId) {
                subscriber.applyInlinePreviewRenderer(previewRenderer)
            }
        }
    }

    /// A compact, `Equatable` snapshot of everything that can affect the PiP target or placeholder.
    /// Used to coalesce participant-state emissions and ignore audio-level-only updates.
    private struct PipSignature: Equatable {
        let localId: String?
        let localCameraEnabled: Bool
        let activeParticipantId: String?
        let remotes: [Remote]

        struct Remote: Equatable {
            let id: String
            let cameraEnabled: Bool
            let isScreenshare: Bool
        }
    }

    private static func pipSignature(for state: ParticipantsState) -> PipSignature {
        PipSignature(
            localId: state.localParticipant?.id,
            localCameraEnabled: state.localParticipant?.isCameraEnabled ?? false,
            activeParticipantId: state.activeParticipantId,
            remotes: state.participants.map {
                PipSignature.Remote(
                    id: $0.id,
                    cameraEnabled: $0.isCameraEnabled,
                    isScreenshare: $0.isScreenshare
                )
            }
        )
    }

    private func subscriberPreviewRenderer(for id: String) -> PictureInPictureVideoRenderer {
        if let existing = subscriberPreviewRenderers[id] {
            return existing
        }
        let renderer = PictureInPictureVideoRenderer()
        subscriberPreviewRenderers[id] = renderer
        return renderer
    }

    private func pruneSubscriberPreviewRenderers(keeping ids: Set<String>) {
        subscriberPreviewRenderers = subscriberPreviewRenderers.filter { ids.contains($0.key) }
    }
}
