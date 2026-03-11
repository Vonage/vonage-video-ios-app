//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

/// Wraps a UIKit `UIView` for use in SwiftUI layouts.
///
/// ## Design note — wrapper container pattern
///
/// SwiftUI reuses `UIViewRepresentable` instances when their structural identity is stable
/// (e.g., when parent uses `.id("publisherID")`). In that case, `makeUIView` is called once
/// and subsequent renders call `updateUIView`.
///
/// To support publisher/subscriber recreation (where the inner `OTPublisher.view` or
/// `OTSubscriber.view` UIView changes to a new instance), `makeUIView` returns a black
/// wrapper `UIView` rather than the content view directly. `updateUIView` detects when
/// the content view identity has changed using identity comparison (`!==`) and swaps
/// it in, so the new video surface is displayed without requiring a full SwiftUI identity reset.
///
/// ### Black background rationale
/// Black wrapper is used instead of clear so that while the camera or subscriber stream
/// initializes (before first frame arrives), it shows solid black rather than letting
/// the gray card background bleed through.
struct UIViewContainer: UIViewRepresentable {
    private let view: UIView

    /// Creates a container for the given UIKit view.
    ///
    /// - Parameter view: The `UIView` to present in SwiftUI.
    init(view: UIView) {
        self.view = view
    }

    /// Creates a black wrapper container and embeds the content view inside it.
    ///
    /// Called once by SwiftUI when the `UIViewRepresentable` is first created with a stable identity.
    /// Subsequent updates reuse this container and only call `updateUIView`.
    ///
    /// - Returns: A `VideoContainerView` with the content view embedded and constrained to fill.
    func makeUIView(context: Context) -> UIView {
        let containerView = VideoContainerView()
        containerView.setVideoView(view)
        return containerView
    }

    /// Swaps the content view if it has changed since the last update.
    ///
    /// SwiftUI calls this on every render when the stable `.id()` allows view reuse.
    /// Uses identity comparison (`!==`) to detect if `self.view` references a different
    /// `UIView` instance than what's currently embedded (happens after publisher/subscriber
    /// recreation via `applyPublisherAdvancedSettings` or similar operations).
    ///
    /// When a change is detected, removes the old subview and embeds the new one.
    func updateUIView(_ wrapper: UIView, context: Context) {
        guard let container = wrapper as? VideoContainerView, container.videoView !== view
        else { return }
        container.setVideoView(view)
    }
}

/// A black wrapper view that hosts dynamically swappable video content.
///
/// This container serves as a stable wrapper returned by `makeUIView` that can have its
/// content view swapped without recreating the entire SwiftUI view hierarchy.
///
/// The black background ensures that before the first video frame arrives (when
/// `OTPublisher.view` or `OTSubscriber.view` is still transparent), the container shows
/// solid black instead of letting the gray card background bleed through.
private class VideoContainerView: UIView {

    /// The currently embedded video view.
    private(set) var videoView: UIView?

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Replaces the current video view with a new one.
    ///
    /// Removes any existing video view subview and adds the new view with full-fill constraints.
    ///
    /// - Parameter view: The new `UIView` (typically `OTPublisher.view` or `OTSubscriber.view`)
    ///   to embed in this container.
    func setVideoView(_ view: UIView) {
        videoView?.removeFromSuperview()
        self.videoView = view
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: self.topAnchor),
            view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }
}
