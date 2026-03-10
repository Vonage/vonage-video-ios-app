//
//  Created by Vonage on 10/03/26.
//

import SwiftUI

/// A view modifier that makes content scrollable when the keyboard appears,
/// ensuring input fields and buttons remain visible.
///
/// Usage: Apply `.keyboardAware()` to views containing text fields that may be
/// obscured by the on-screen keyboard.
///
/// Manual Testing Required:
/// - Verify Join button remains visible when keyboard appears on Landing page
/// - Verify Join button remains visible when keyboard appears on Waiting room
/// - Test in both portrait and landscape orientations
/// - Test on various iPhone and iPad screen sizes
/// - Verify keyboard dismisses when scrolling down
struct KeyboardAwareModifier: ViewModifier {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    func body(content: Content) -> some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .contentMargins(.bottom, bottomMargin, for: .scrollContent)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Dynamic bottom margin based on size class to prevent content from being too crowded
    private var bottomMargin: CGFloat {
        if verticalSizeClass == .compact {
            // Landscape orientation - tighter spacing
            return 8
        } else {
            // Portrait orientation - more generous spacing
            return 16
        }
    }
}

extension View {
    /// Makes the view keyboard-aware by wrapping it in a scroll view
    /// that automatically scrolls to keep focused text fields visible.
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }
}
