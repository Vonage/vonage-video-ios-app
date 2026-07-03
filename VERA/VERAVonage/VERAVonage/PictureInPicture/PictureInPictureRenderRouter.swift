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

    /// Shared renderer that attaches to whichever *remote* participant is the PiP target.
    let videoRenderer = PictureInPictureVideoRenderer()

    /// The renderer currently feeding the PiP sample-buffer layer: the publisher's own permanent
    /// renderer when the local participant is the target, the shared `videoRenderer` for remotes.
    /// The controller, placeholders, and frame checks must all go through this.
    private(set) var activePipRenderer: PictureInPictureVideoRenderer

    /// Per-remote renderers that keep each remote tile alive after the shared `videoRenderer` moves
    /// to another participant (active-speaker switching).
    private var subscriberPreviewRenderers: [String: PictureInPictureVideoRenderer] = [:]

    init() {
        activePipRenderer = videoRenderer
    }

    /// Routes the PiP feed to `targetId`'s stream.
    ///
    /// The local publisher renders through its own permanent renderer, so targeting it only selects
    /// that renderer as the PiP feed — no `videoRender` rewiring. Remotes attach the shared
    /// `videoRenderer` as before.
    ///
    /// - Parameter forceReattach: detach any existing custom renderer from a *remote* target first,
    ///   so a stale pipeline is fully rebuilt (used when the target's camera comes back on).
    /// - Throws: ``RoutingError/targetStreamNotFound(_:)`` when no publisher or subscriber matches
    ///   `targetId`, so the caller can leave its target state untouched.
    func applyRenderer(
        to targetId: String,
        call: VonageCall,
        inlineView: () -> AnyView,
        forceReattach: Bool = false
    ) async throws {
        if call.publisher.id == targetId {
            activePipRenderer = call.publisher.inlineVideoRenderer
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
            activePipRenderer = videoRenderer
            subscriber.applyPictureInPictureRenderer(videoRenderer, inlineView: inlineView())
            return
        }

        throw RoutingError.targetStreamNotFound(targetId)
    }

    /// Detaches the PiP feed from the current target, keeping that tile alive: the publisher keeps
    /// rendering through its permanent renderer (nothing to do), a remote is handed to its
    /// per-participant preview renderer.
    func clearTarget(_ currentPipTargetId: String?, call: VonageCall?) async {
        guard let currentPipTargetId, let call else { return }

        if call.publisher.id == currentPipTargetId {
            return
        }

        let previewRenderer = subscriberPreviewRenderer(for: currentPipTargetId)
        if let subscriber = await call.subscriber(for: currentPipTargetId) {
            subscriber.applyInlinePreviewRenderer(previewRenderer)
        }
    }

    func pruneSubscriberPreviewRenderers(keeping ids: Set<String>) {
        subscriberPreviewRenderers = subscriberPreviewRenderers.filter { ids.contains($0.key) }
    }

    /// Resets shared state for teardown: stops placeholders, detaches the publisher's renderer from
    /// the PiP feed, and drops all preview renderers.
    func reset() {
        activePipRenderer.stopPlaceholder()
        videoRenderer.stopPlaceholder()
        activePipRenderer = videoRenderer
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
