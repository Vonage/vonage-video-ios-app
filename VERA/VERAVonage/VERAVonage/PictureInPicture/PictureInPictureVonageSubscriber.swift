//
//  Created by Vonage on 8/7/26.
//

import Foundation
import OpenTok
import UIKit

/// A `VonageSubscriber` that renders through a custom `PictureInPictureVideoRenderer` so its frames
/// can feed the Picture-in-Picture window, and that keeps its video subscription alive while it is
/// the PiP target. Used only when `allowPictureInPicture` is enabled; otherwise the base
/// `VonageSubscriber` (OpenTok's native GL view) is used, keeping the non-PiP path untouched.
final class PictureInPictureVonageSubscriber: VonageSubscriber {
    /// Permanent renderer for this participant's video, attached once in ``setup()`` and never
    /// rewired. The tile always embeds it, and PiP taps its frames via `pipBufferDisplayLayer`
    /// when this participant is the target — so there is no mid-call `videoRender` swap.
    let inlineVideoRenderer = PictureInPictureVideoRenderer()

    /// `true` while this participant is the PiP target. Keeps the video subscription alive even
    /// when the tile is hidden, so the PiP window keeps receiving frames.
    private var isPictureInPictureTargetStream = false

    override func makeVideoView() -> UIView {
        inlineVideoRenderer
    }

    override func setup() {
        otSubscriber.videoRender = inlineVideoRenderer
        // The SDK pauses rendering on resign-active by default; PiP needs frames in the background.
        NotificationCenter.default.removeObserver(
            otSubscriber,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        super.setup()
    }

    /// While targeted, force the video subscription on regardless of tile visibility.
    override func setActiveSubscription(_ visible: Bool) {
        if isPictureInPictureTargetStream {
            guard subscriberDidConnect else { return }
            otSubscriber.subscribeToVideo = true
            return
        }
        super.setActiveSubscription(visible)
    }

    /// Marks this participant as the PiP target (or releases it).
    ///
    /// While targeted, the video subscription is forced on regardless of tile visibility so the
    /// PiP window keeps receiving frames (e.g. while the app is backgrounded and no tile is
    /// rendered). Releasing restores visibility-driven subscription.
    func setPictureInPictureTarget(_ isTarget: Bool) {
        isPictureInPictureTargetStream = isTarget
        guard subscriberDidConnect else { return }
        if isTarget {
            otSubscriber.subscribeToVideo = true
        } else if visibilityCount <= 0 {
            otSubscriber.subscribeToVideo = false
        }
    }
}
