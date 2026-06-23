//
//  Created by Vonage on 21/6/26.
//

import AVKit
import SwiftUI
import UIKit

/// Hosts the PiP inline `AVSampleBufferDisplayLayer` and configures PiP from that container.
///
/// Mirrors the Vonage Picture-in-Picture sample: the same UIView that shows inline video
/// must be passed as `activeVideoCallSourceView` to `AVPictureInPictureController`.
struct PictureInPictureInlineVideoView: UIViewRepresentable {
    let renderer: PictureInPictureVideoRenderer
    let configurationToken: UUID
    let onSourceViewReady: (UIView, CGRect) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            renderer: renderer,
            configurationToken: configurationToken,
            onSourceViewReady: onSourceViewReady
        )
    }

    func makeUIView(context: Context) -> PictureInPictureVideoContainerView {
        let containerView = PictureInPictureVideoContainerView()
        containerView.backgroundColor = .black
        let coordinator = context.coordinator
        coordinator.attachDisplayLayer(to: containerView)
        containerView.onLayout = { [weak containerView] in
            guard let containerView else { return }
            coordinator.attachDisplayLayer(to: containerView)
        }
        containerView.onEnterWindow = { [weak containerView] in
            guard let containerView else { return }
            coordinator.configurePictureInPictureIfNeeded(for: containerView)
        }
        return containerView
    }

    func updateUIView(_ uiView: PictureInPictureVideoContainerView, context: Context) {
        if context.coordinator.configurationToken != configurationToken {
            context.coordinator.configurationToken = configurationToken
            context.coordinator.resetConfiguration()
        }

        context.coordinator.onSourceViewReady = onSourceViewReady
        context.coordinator.attachDisplayLayer(to: uiView)
        context.coordinator.configurePictureInPictureIfNeeded(for: uiView)
    }

    final class Coordinator {
        let renderer: PictureInPictureVideoRenderer
        var configurationToken: UUID
        var onSourceViewReady: (UIView, CGRect) -> Void
        private var didConfigurePictureInPicture = false

        init(
            renderer: PictureInPictureVideoRenderer,
            configurationToken: UUID,
            onSourceViewReady: @escaping (UIView, CGRect) -> Void
        ) {
            self.renderer = renderer
            self.configurationToken = configurationToken
            self.onSourceViewReady = onSourceViewReady
        }

        func attachDisplayLayer(to containerView: PictureInPictureVideoContainerView) {
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

        func configurePictureInPictureIfNeeded(for view: PictureInPictureVideoContainerView) {
            guard !didConfigurePictureInPicture, view.window != nil else { return }

            let frame = view.bounds
            guard frame.width > 0, frame.height > 0 else { return }

            didConfigurePictureInPicture = true
            onSourceViewReady(view, frame)
        }

        func resetConfiguration() {
            didConfigurePictureInPicture = false
        }
    }
}

final class PictureInPictureVideoContainerView: UIView {
    var onEnterWindow: (() -> Void)?
    var onLayout: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            onEnterWindow?()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
        if window != nil {
            onEnterWindow?()
        }
    }
}
