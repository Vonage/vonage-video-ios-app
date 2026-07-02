//
//  Created by Vonage on 21/6/26.
//

import Foundation
import SwiftUI
import VERADomain

/// Routes the shared Picture-in-Picture renderer onto whichever participant is the current PiP
/// target, and keeps every other tile alive with a dedicated preview renderer.
///
/// OpenTok's default views cannot be revived once a custom `videoRender` has been attached, so a
/// participant that stops being the PiP/active-speaker target is handed to its own preview renderer
/// rather than reverting to the SDK view (which would leave a gray tile). This type owns all of
/// those renderers and the publisher/subscriber wiring; the orchestrator decides *when* to move the
/// target, this decides *how* the streams follow.
@MainActor
final class PictureInPictureRenderRouter {
    enum RoutingError: Error {
        /// No publisher or subscriber stream matched the requested target id (e.g. a participant
        /// was announced before its subscriber exists yet).
        case targetStreamNotFound(String)
    }

    /// The renderer that feeds the AVKit PiP sample-buffer layer. Moves between targets.
    let videoRenderer = PictureInPictureVideoRenderer()

    /// Keeps the local tile alive when the publisher stops being the PiP target (the shared
    /// `videoRenderer` moves to the remote target in that case).
    private let publisherPreviewRenderer = PictureInPictureVideoRenderer()

    /// Per-remote renderers that keep each remote tile alive after the shared `videoRenderer` moves
    /// to another participant (active-speaker switching).
    private var subscriberPreviewRenderers: [String: PictureInPictureVideoRenderer] = [:]

    /// Attaches the shared renderer to `targetId`'s stream.
    ///
    /// - Parameter forceReattach: detach any existing custom renderer from the target first, so a
    ///   stale pipeline is fully rebuilt (used when the target's camera comes back on).
    /// - Throws: ``RoutingError/targetStreamNotFound(_:)`` when no publisher or subscriber matches
    ///   `targetId`, so the caller can leave its target state untouched.
    func applyRenderer(
        to targetId: String,
        call: VonageCall,
        inlineView: AnyView,
        forceReattach: Bool = false
    ) async throws {
        if call.publisher.id == targetId {
            if forceReattach {
                call.publisher.restoreDefaultVideoView()
            }
            videoRenderer.isMirrored = call.publisher.cameraPosition == .front
            call.publisher.applyPictureInPictureRenderer(videoRenderer, inlineView: inlineView)
            return
        }

        if let subscriber = await call.subscriber(for: targetId) {
            if forceReattach {
                subscriber.clearPictureInPictureRenderer()
            }
            // The app mirrors remote camera tiles in the meeting room (see
            // ParticipantVideoCard.shouldFlipHorizontally). The PiP target opts out of that SwiftUI
            // flip and mirrors here instead, so the inline tile and the PiP window — which bypasses
            // SwiftUI — stay identical.
            videoRenderer.isMirrored = true
            subscriber.applyPictureInPictureRenderer(videoRenderer, inlineView: inlineView)
            return
        }

        throw RoutingError.targetStreamNotFound(targetId)
    }

    /// Hands the publisher's tile straight to its dedicated preview renderer with a single
    /// `videoRender` reassignment when it stops being the PiP target. We deliberately avoid the
    /// `restoreDefaultVideoView()` path here: setting `OTPublisher.videoRender` to nil and
    /// immediately reassigning it can leave the publisher not delivering frames, freezing the local
    /// self-view.
    ///
    /// - Returns: `true` when the handoff applied (publisher was the previous target and is no
    ///   longer the target), so the caller can skip the generic clear path.
    func handlePublisherHandoff(
        previousTargetId: String?,
        newTargetId: String?,
        call: VonageCall?
    ) -> Bool {
        guard let call,
            previousTargetId == call.publisher.id,
            let newTargetId,
            newTargetId != call.publisher.id
        else {
            return false
        }

        publisherPreviewRenderer.isMirrored = call.publisher.cameraPosition == .front
        call.publisher.applyInlinePreviewRenderer(publisherPreviewRenderer)
        return true
    }

    /// Detaches the shared renderer from the current target, keeping that tile alive: the publisher
    /// reverts to its default view, a remote is handed to its per-participant preview renderer.
    func clearTarget(_ currentPipTargetId: String?, call: VonageCall?) async {
        guard let currentPipTargetId, let call else { return }

        if call.publisher.id == currentPipTargetId {
            call.publisher.restoreDefaultVideoView()
        } else {
            let previewRenderer = subscriberPreviewRenderer(for: currentPipTargetId)
            if let subscriber = await call.subscriber(for: currentPipTargetId) {
                subscriber.applyInlinePreviewRenderer(previewRenderer)
            }
        }
    }

    /// Reverts the publisher to its default view on teardown when it is the current target.
    func restorePublisherIfTarget(_ currentPipTargetId: String?, call: VonageCall?) {
        guard let currentPipTargetId, call?.publisher.id == currentPipTargetId else { return }
        call?.publisher.restoreDefaultVideoView()
    }

    func pruneSubscriberPreviewRenderers(keeping ids: Set<String>) {
        subscriberPreviewRenderers = subscriberPreviewRenderers.filter { ids.contains($0.key) }
    }

    /// Resets shared state for teardown: stops the placeholder and drops all preview renderers.
    func reset() {
        videoRenderer.stopPlaceholder()
        subscriberPreviewRenderers.removeAll()
    }

    private func subscriberPreviewRenderer(for id: String) -> PictureInPictureVideoRenderer {
        if let existing = subscriberPreviewRenderers[id] {
            return existing
        }
        let renderer = PictureInPictureVideoRenderer()
        subscriberPreviewRenderers[id] = renderer
        return renderer
    }
}
