//
//  Created by Vonage on 21/6/26.
//

import Combine
import Foundation
import SwiftUI
import UIKit
import VERADomain

/// Coordinates Picture-in-Picture for an active Vonage call.
@MainActor
public final class PictureInPictureManager: ObservableObject {
    @Published public private(set) var isInPictureInPicture = false
    @Published public private(set) var canStartPictureInPicture = false
    @Published public private(set) var pipTargetParticipantId: String?
    @Published public private(set) var debugSnapshot = PictureInPictureDebugSnapshot()

    let videoRenderer = PictureInPictureVideoRenderer()

    /// Dedicated renderer that keeps the local tile alive when the publisher stops being the PiP
    /// target (the shared `videoRenderer` moves to the remote target in that case).
    private let publisherPreviewRenderer = PictureInPictureVideoRenderer()

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
            self.record(event: isActive ? "entered PiP" : "exited PiP")
            if !isActive {
                self.wantsPictureInPicture = false
            }
            self.publishDebugSnapshot()
        }
        pipController.onPictureInPicturePossibleDidChange = { [weak self] in
            guard let self else { return }
            self.canStartPictureInPicture = self.pipController.canStartPictureInPicture
            self.record(event: "possible=\(self.canStartPictureInPicture)")
            if self.canStartPictureInPicture && self.wantsPictureInPicture {
                self.startPictureInPictureIfPossible()
            }
            self.publishDebugSnapshot()
        }
        pipController.onPictureInPictureFailed = { [weak self] error in
            self?.record(event: "failed to start", error: error.localizedDescription)
            self?.wantsPictureInPicture = false
            self?.publishDebugSnapshot()
        }
        publishDebugSnapshot()
    }

    public func bind(to call: VonageCall) {
        guard self.call == nil else {
            record(event: "bind skipped (already bound)")
            return
        }
        self.call = call
        record(event: "bound to call")

        call.participantsPublisher
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

        publishDebugSnapshot()
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
            record(event: "configure blocked: not supported", error: "PiP unsupported on this device")
            return
        }
        guard videoFrame.width > 1, videoFrame.height > 1 else {
            record(event: "configure deferred: zero bounds \(videoFrame)")
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
                record(event: "reconfiguring stale PiP controller")
                _ = pipController.reconfigure(
                    with: sourceView,
                    videoRenderer: videoRenderer,
                    videoFrame: videoFrame
                )
            } else {
                record(event: "configure skipped (already configured)")
                publishDebugSnapshot()
                return
            }
        }

        canStartPictureInPicture = pipController.canStartPictureInPicture
        record(
            event: "configured \(Int(videoFrame.width))x\(Int(videoFrame.height)) possible=\(canStartPictureInPicture)")

        if wantsPictureInPicture {
            startPictureInPictureIfPossible()
        }
        publishDebugSnapshot()
    }

    public func requestPictureInPicture() {
        wantsPictureInPicture = true
        record(event: "request PiP frames=\(videoRenderer.renderedFrameCount)")
        publishDebugSnapshot()
        startPictureInPictureIfPossible()
    }

    public func startPictureInPictureIfPossible() {
        guard pipTargetCameraEnabled else {
            record(event: "start blocked: pip target camera off")
            publishDebugSnapshot()
            return
        }

        guard pipController.canStartPictureInPicture else {
            record(event: "start blocked: not possible yet frames=\(videoRenderer.renderedFrameCount)")
            publishDebugSnapshot()
            return
        }
        record(event: "starting PiP")
        pipController.startPictureInPicture()
        publishDebugSnapshot()
    }

    public func tearDown() {
        cancellables.removeAll()
        clearCurrentPipTarget()
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
        record(event: "torn down")
        publishDebugSnapshot()
    }

    private func updatePipTarget(for state: ParticipantsState) async {
        if isInPictureInPicture || pipController.isInPictureInPicture {
            record(event: "pip target update skipped (in PiP)")
            publishDebugSnapshot()
            return
        }

        let targetId = pipTargetId(for: state)
        let targetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        if targetId == currentPipTargetId {
            let cameraWasEnabled = pipTargetCameraEnabled
            pipTargetCameraEnabled = targetCameraEnabled

            if cameraWasEnabled && !targetCameraEnabled {
                record(event: "pip target camera disabled — resetting PiP controller")
                videoRenderer.prepareForPipRefresh()
                pipController.tearDown()
                canStartPictureInPicture = false
                publishDebugSnapshot()
                return
            }

            if !cameraWasEnabled && targetCameraEnabled, let targetId {
                record(event: "pip target camera re-enabled — refreshing PiP pipeline")
                await refreshPipPipeline(targetId: targetId, state: state)
            }
            return
        }

        let currentTargetHasCamera = isCameraEnabled(participantId: currentPipTargetId, in: state)
        if wantsPictureInPicture,
            currentPipTargetId != nil,
            currentTargetHasCamera,
            targetId != currentPipTargetId
        {
            record(event: "pip target update deferred (pending PiP)")
            publishDebugSnapshot()
            return
        }

        await switchPipTarget(to: targetId, state: state)
    }

    private func switchPipTarget(to targetId: String?, state: ParticipantsState) async {
        let previousTargetId = currentPipTargetId
        invalidatePipConfiguration()
        clearCurrentPipTarget()
        keepPublisherRenderingIfNeeded(previousTargetId: previousTargetId, newTargetId: targetId)
        currentPipTargetId = targetId
        pipTargetParticipantId = nil
        pipTargetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        guard let targetId, let call else {
            record(event: "no pip target")
            publishDebugSnapshot()
            return
        }

        await applyPipRenderer(to: targetId, call: call)
        record(event: "pip target switched \(targetId) camera=\(pipTargetCameraEnabled)")
        publishDebugSnapshot()
    }

    private func refreshPipPipeline(targetId: String, state: ParticipantsState) async {
        invalidatePipConfiguration()
        pipTargetCameraEnabled = isCameraEnabled(participantId: targetId, in: state)

        guard let call else { return }
        await applyPipRenderer(to: targetId, call: call, forceReattach: true)
        publishDebugSnapshot()
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
            record(event: "pip target missing stream \(targetId)", error: "subscriber not found")
            return
        }

        currentPipTargetId = targetId
        pipTargetParticipantId = targetId
    }

    private func invalidatePipConfiguration() {
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

    private func isCameraEnabled(participantId: String?, in state: ParticipantsState) -> Bool {
        guard let participantId else { return false }

        if state.localParticipant?.id == participantId {
            return state.localParticipant?.isCameraEnabled == true
        }

        return state.participants.first(where: { $0.id == participantId })?.isCameraEnabled == true
    }

    /// When the publisher was the PiP target and we switch to a remote, keep the local tile
    /// rendering through a dedicated renderer. The publisher's default `OTPublisher.view` cannot be
    /// revived after a custom `videoRender` was attached, so reverting to it would blank the tile.
    private func keepPublisherRenderingIfNeeded(previousTargetId: String?, newTargetId: String?) {
        guard let call,
            previousTargetId == call.publisher.id,
            let newTargetId,
            newTargetId != call.publisher.id
        else { return }

        call.publisher.applyInlinePreviewRenderer(publisherPreviewRenderer)
        record(event: "publisher inline preview renderer attached")
    }

    private func clearCurrentPipTarget() {
        guard let currentPipTargetId else { return }

        if call?.publisher.id == currentPipTargetId {
            call?.publisher.restoreDefaultVideoView()
        } else {
            Task { [weak self] in
                guard let self, let call = self.call else { return }
                if let subscriber = await call.subscriber(for: currentPipTargetId) {
                    subscriber.clearPictureInPictureRenderer()
                }
            }
        }
    }

    private func record(event: String, error: String? = nil) {
        PictureInPictureDiagnostics.log("[PiP] \(event)")
        if let error {
            PictureInPictureDiagnostics.error("[PiP] \(error)")
        }
        debugSnapshot.lastEvent = event
        debugSnapshot.lastError = error
    }

    private func publishDebugSnapshot() {
        debugSnapshot.isBound = call != nil
        debugSnapshot.pipTargetId = pipTargetParticipantId
        debugSnapshot.isControllerConfigured = pipController.isConfigured
        debugSnapshot.isSupported = pipController.isPictureInPictureSupported
        debugSnapshot.isPossible = pipController.canStartPictureInPicture
        debugSnapshot.isInPictureInPicture = isInPictureInPicture
        debugSnapshot.renderedFrameCount = videoRenderer.renderedFrameCount
        debugSnapshot.wantsPictureInPicture = wantsPictureInPicture
    }
}
