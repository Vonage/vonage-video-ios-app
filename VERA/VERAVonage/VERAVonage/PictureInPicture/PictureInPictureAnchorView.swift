//
//  Created by Vonage on 3/7/26.
//

import OSLog
import SwiftUI
import UIKit

/// Invisible, non-interactive view that anchors the Picture-in-Picture morph animation to the
/// area it spans (the meeting room content).
///
/// AVKit animates the PiP window from/to `activeVideoCallSourceView`. Anchoring to a participant
/// tile couples PiP startability to that tile's mount timing (a SwiftUI render that can lag or,
/// while backgrounding, never come), and morphing from a single tile looks wrong whenever PiP
/// shows a different participant. This view is mounted with the meeting room itself, so PiP is
/// configurable as soon as the room is on screen, and the morph reads as "the call shrinks into
/// PiP / expands back" regardless of who PiP is showing.
public struct PictureInPictureAnchorView: UIViewRepresentable {
    private let onReady: (UIView, CGRect) -> Void

    /// - Parameter onReady: Called once per underlying view instance when it is in a window with a
    ///   usable size — wire this to the orchestrator's `configurePictureInPicture`.
    public init(onReady: @escaping (UIView, CGRect) -> Void) {
        self.onReady = onReady
    }

    public func makeUIView(context: Context) -> AnchorUIView {
        let view = AnchorUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.onReady = onReady
        return view
    }

    public func updateUIView(_ uiView: AnchorUIView, context: Context) {
        uiView.onReady = onReady
    }

    public final class AnchorUIView: UIView {
        private static let logger = Logger(subsystem: "com.vonage.vera", category: "PictureInPicture")

        var onReady: ((UIView, CGRect) -> Void)?
        private var didNotify = false

        override public func didMoveToWindow() {
            super.didMoveToWindow()
            notifyIfEligible()
        }

        override public func layoutSubviews() {
            super.layoutSubviews()
            notifyIfEligible()
        }

        private func notifyIfEligible() {
            guard !didNotify,
                let onReady,
                window != nil,
                bounds.width > 1,
                bounds.height > 1
            else { return }

            didNotify = true
            Self.logger.debug("anchor.ready \(String(describing: self.bounds.size), privacy: .public)")
            // Deliver outside the layout pass: the callback publishes orchestrator state, and
            // publishing during a view update is undefined behavior in SwiftUI.
            let frame = bounds
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                onReady(self, frame)
            }
        }
    }
}
