//
//  Created by Vonage on 16/7/25.
//

import SwiftUI

/// Wraps a UIKit `UIView` for use in SwiftUI layouts.
///
/// Use `UIViewContainer` when integrating SDK views (e.g., OpenTok video view)
/// into SwiftUI hierarchies without custom bridging logic.
///
/// - Important: The wrapped view is owned externally and not mutated by the container.
struct UIViewContainer: UIViewRepresentable {
    private let view: UIView

    /// Creates a container for the given UIKit view.
    ///
    /// - Parameter view: The `UIView` to present in SwiftUI.
    init(view: UIView) {
        self.view = view
    }

    /// Returns the underlying UIKit view to display.
    ///
    /// - Parameter context: The representable context (unused).
    /// - Returns: The wrapped `UIView`.
    func makeUIView(context: Context) -> UIView { view }

    /// No-op: the wrapped view is managed externally.
    ///
    /// - Parameters:
    ///   - uiView: The view created in `makeUIView(context:)`.
    ///   - context: The representable context (unused).
    func updateUIView(_ uiView: UIView, context: Context) {}
}
