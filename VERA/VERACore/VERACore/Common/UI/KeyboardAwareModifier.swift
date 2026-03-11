//
//  Created by Vonage on 10/03/26.
//

import Combine
import SwiftUI

/// A view modifier that handles keyboard appearance by wrapping content in a scroll view
/// and adding bottom padding based on keyboard height.
///
/// Usage:
/// - `.keyboardAware()` - Default behavior with full keyboard padding
/// - `.keyboardAware(paddingDivider: 2)` - Half keyboard height as padding
/// - `.keyboardAware(paddingDivider: 3, scrollToBottom: true)` - Custom padding with auto-scroll
/// - `.keyboardAware(scrollToId: "joinButton")` - Scroll to specific component when keyboard appears
struct KeyboardAwareModifier: ViewModifier {
    let paddingDivider: CGFloat
    let scrollToBottom: Bool
    let scrollToId: String?

    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        content
                            .padding(1)

                        // Bottom spacer to prevent content from hiding behind keyboard
                        Color.clear
                            .frame(height: bottomPadding)
                            .id("bottomAnchor")
                    }
                }
                .scrollDismissesKeyboard(.automatic)
                .scrollIndicators(.visible)
                .onReceive(keyboardPublisher) { height in
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight = height

                        if height > 0 {
                            // Small delay to ensure layout is updated
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    // Scroll to custom ID if provided, otherwise to bottom anchor if enabled
                                    if let targetId = scrollToId {
                                        proxy.scrollTo(targetId, anchor: .center)
                                    } else if scrollToBottom {
                                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                }
                .onTapGesture {
                    dismissKeyboard()
                }
            }
        }
    }

    /// Calculated bottom padding based on keyboard height and divider
    private var bottomPadding: CGFloat {
        keyboardHeight / paddingDivider
    }

    /// Dismisses the keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    /// Publisher that emits keyboard height changes
    private var keyboardPublisher: AnyPublisher<CGFloat, Never> {
        Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .compactMap { notification in
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
                },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in CGFloat(0) }
        )
        .eraseToAnyPublisher()
    }
}

extension View {
    /// Makes the view keyboard-aware by wrapping it in a scroll view with bottom padding.
    ///
    /// - Parameters:
    ///   - paddingDivider: Divides keyboard height to calculate bottom padding (default: 1.0 = full height)
    ///   - scrollToBottom: Whether to auto-scroll to bottom when keyboard appears (default: false)
    ///   - scrollToId: Optional ID of a specific component to scroll to when keyboard appears (takes precedence over scrollToBottom)
    ///
    /// Examples:
    /// - `.keyboardAware()` - Full keyboard height as padding
    /// - `.keyboardAware(paddingDivider: 2)` - Half keyboard height
    /// - `.keyboardAware(paddingDivider: 1.5, scrollToBottom: true)` - 2/3 height with auto-scroll
    /// - `.keyboardAware(scrollToId: "joinButton")` - Scroll to component with ID "joinButton"
    func keyboardAware(
        paddingDivider: CGFloat = 1.0, scrollToBottom: Bool = false, scrollToId: String? = nil
    ) -> some View {
        modifier(
            KeyboardAwareModifier(
                paddingDivider: paddingDivider, scrollToBottom: scrollToBottom, scrollToId: scrollToId))
    }
}
