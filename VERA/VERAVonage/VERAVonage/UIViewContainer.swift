//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

/// Wraps a UIKit `UIView` for use in SwiftUI layouts.
///
/// ## Design note — wrapper container pattern
///
/// SwiftUI reuses `UIViewRepresentable` instances when their structural identity is stable
/// (e.g. when a parent uses `.id("publisherID")`). In that case `makeUIView` is only called
/// once, and subsequent renders only call `updateUIView`.
///
/// To support publisher recreation (where the inner `OTPublisher.view` `UIView` changes to a
/// new instance), `makeUIView` returns a transparent wrapper `UIView` rather than the content
/// view directly. `updateUIView` detects when the stored content view differs from the one
/// currently installed as a subview and swaps it in, so the new publisher's video surface is
/// displayed without requiring a full SwiftUI identity reset.
struct UIViewContainer: UIViewRepresentable {
    private let view: UIView

    /// Creates a container for the given UIKit view.
    ///
    /// - Parameter view: The `UIView` to present in SwiftUI.
    init(view: UIView) {
        self.view = view
    }

    /// Creates a black wrapper and embeds the content view inside it.
    ///
    /// Black is used instead of clear so that while the camera or subscriber stream is
    /// initialising (before the first frame arrives, when the OTPublisher/OTSubscriber
    /// UIView is still transparent), the wrapper shows solid black rather than letting
    /// the gray card background bleed through.
    func makeUIView(context: Context) -> UIView {
        let wrapper = UIView()
        wrapper.backgroundColor = .black
        embed(view, in: wrapper)
        return wrapper
    }

    /// Swaps the content view if the publisher has been recreated since `makeUIView` ran.
    ///
    /// Because `.id("publisherID")` is a stable key, SwiftUI reuses the same wrapper and
    /// only calls this method on subsequent renders. If `self.view` is a different `UIView`
    /// instance (i.e. the publisher was recreated), the old subview is removed and the
    /// new one embedded.
    func updateUIView(_ wrapper: UIView, context: Context) {
        guard wrapper.subviews.first !== view else { return }
        wrapper.subviews.forEach { $0.removeFromSuperview() }
        embed(view, in: wrapper)
    }

    // MARK: - Private

    private func embed(_ content: UIView, in wrapper: UIView) {
        content.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: wrapper.topAnchor),
            content.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        ])
    }
}
