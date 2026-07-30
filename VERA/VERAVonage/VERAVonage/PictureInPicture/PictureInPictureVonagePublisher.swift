//
//  Created by Vonage on 8/7/26.
//

import Foundation
import OpenTok
import SwiftUI
import UIKit
import VERADomain

/// A `VonagePublisher` that renders the local self-view through a custom
/// `PictureInPictureVideoRenderer` so its frames can feed the Picture-in-Picture window. Used only
/// when `allowPictureInPicture` is enabled; otherwise the base `VonagePublisher` (OpenTok's native
/// view, which mirrors the front camera itself) is used, keeping the non-PiP path untouched.
///
/// The renderer is attached at publish time (``setup()``) — the waiting room still uses
/// `OTPublisher.view` beforehand — and the self-view is mirrored in pixels for the front camera to
/// match the selfie-preview convention across both the tile and the PiP window.
final class PictureInPictureVonagePublisher: VonagePublisher {
    /// Permanent renderer for the local self-view, attached once in ``setup()`` and never rewired.
    let inlineVideoRenderer = PictureInPictureVideoRenderer()
    private var isInlineRendererAttached = false

    public override var view: AnyView {
        isInlineRendererAttached
            ? AnyView(UIViewContainer(view: inlineVideoRenderer))
            : super.view
    }

    public override var cameraPosition: CameraPosition {
        get { super.cameraPosition }
        set {
            super.cameraPosition = newValue
            updateInlineRendererMirroring()
        }
    }

    public override func switchCamera(to cameraDeviceID: String) {
        super.switchCamera(to: cameraDeviceID)
        updateInlineRendererMirroring()
    }

    override func setup() {
        super.setup()
        attachInlineRendererIfNeeded()
    }

    public override func cleanUp() {
        detachInlineRenderer()
        super.cleanUp()
    }

    /// Keeps the self-view mirrored for the front camera (selfie-preview convention) and
    /// un-mirrored for the back camera. Applied to the pixels so the tile and PiP window agree.
    private func updateInlineRendererMirroring() {
        inlineVideoRenderer.isMirrored = otPublisher.cameraPosition == .front
    }

    /// Attaches the permanent local renderer at publish time. The waiting room uses
    /// `OTPublisher.view` before this point and the publisher is recreated for each call, so the
    /// default view is never needed again afterwards.
    private func attachInlineRendererIfNeeded() {
        guard !isInlineRendererAttached, !isScreenshare else { return }
        isInlineRendererAttached = true
        updateInlineRendererMirroring()
        otPublisher.videoRender = inlineVideoRenderer
        // The SDK pauses its capture pipeline on resign-active by default, which would blank PiP;
        // during a call the local video must keep flowing in the background.
        NotificationCenter.default.removeObserver(
            otPublisher,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        updateParticipant()
    }

    /// Detaches the renderer at end of call, right before the publisher is destroyed.
    func detachInlineRenderer() {
        guard isInlineRendererAttached else { return }
        isInlineRendererAttached = false
        otPublisher.videoRender = nil
        updateParticipant()
    }
}
