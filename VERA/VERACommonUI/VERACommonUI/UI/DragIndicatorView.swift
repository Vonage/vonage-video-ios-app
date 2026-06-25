//
//  Created by Vonage on 22/06/2026.
//

import SwiftUI

private enum DragIndicatorViewConstants {
    static let opacity: CGFloat = 0.30
    static let width: CGFloat = 36
    static let height: CGFloat = 5
    static let paddingTop: CGFloat = 8
    static let paddingBottom: CGFloat = 8
}

/// A small visual handle used at the top of custom bottom-sheet style surfaces.
///
/// `DragIndicatorView` renders a themed capsule that communicates that the
/// surrounding surface can be dragged or dismissed. It is intended for custom
/// sheet content where the system drag indicator may be hidden or unreliable,
/// such as landscape layouts with scrollable content.
///
/// The view is visual only; it does not add drag handling by itself. Place it
/// above the scrollable content of the sheet and keep the actual sheet gesture
/// management in the presenting container.
public struct DragIndicatorView: View {
    @Environment(\.meetingRoomTheme) private var theme

    /// Creates a drag indicator using the current meeting room theme.
    public init() {}

    public var body: some View {
        Capsule()
            .fill(theme.secondary.opacity(DragIndicatorViewConstants.opacity))
            .frame(width: DragIndicatorViewConstants.width, height: DragIndicatorViewConstants.height)
            .padding(.top, DragIndicatorViewConstants.paddingTop)
            .padding(.bottom, DragIndicatorViewConstants.paddingBottom)
    }
}
