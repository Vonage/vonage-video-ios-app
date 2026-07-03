//
//  Created by Vonage on 21/6/26.
//

import AVKit
import OSLog
import SwiftUI
import UIKit

/// Hosts the shared PiP renderer's inline `AVSampleBufferDisplayLayer` inside a remote PiP
/// target's tile.
///
/// Purely a display surface: the PiP controller is anchored to the room-level
/// ``PictureInPictureAnchorView``, so this view's mount timing never gates PiP startability.
struct PictureInPictureInlineVideoView: UIViewRepresentable {
    private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")

    let renderer: PictureInPictureVideoRenderer

    func makeUIView(context: Context) -> PictureInPictureVideoContainerView {
        Self.logger.debug("inline.makeUIView")
        let containerView = PictureInPictureVideoContainerView()
        containerView.backgroundColor = .black
        attachDisplayLayer(to: containerView)
        containerView.onLayout = { [weak containerView] in
            guard let containerView else { return }
            attachDisplayLayer(to: containerView)
        }
        return containerView
    }

    func updateUIView(_ uiView: PictureInPictureVideoContainerView, context: Context) {
        attachDisplayLayer(to: uiView)
    }

    /// Moves the renderer's inline display layer into this container. The layer can only live in
    /// one superlayer, so the most recently mounted tile hosts it.
    private func attachDisplayLayer(to containerView: PictureInPictureVideoContainerView) {
        let displayLayer = renderer.inlineDisplayLayer
        if displayLayer.superlayer !== containerView.layer {
            displayLayer.removeFromSuperlayer()
            displayLayer.videoGravity = .resizeAspect
            containerView.layer.addSublayer(displayLayer)
        }
        if containerView.bounds.width > 0, containerView.bounds.height > 0 {
            displayLayer.frame = containerView.bounds
        }
    }
}

final class PictureInPictureVideoContainerView: UIView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
