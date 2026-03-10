//
//  Created by Vonage on 10/03/26.
//

import Combine
import SwiftUI

/// A view modifier that adjusts content position when the keyboard appears,
/// ensuring input fields and buttons remain visible by adding bottom padding.
///
/// Usage: Apply `.keyboardAware()` to container views with text fields.
struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    content
                        .frame(minHeight: geometry.size.height)

                    // Spacer that grows with keyboard height
                    Color.clear
                        .frame(height: keyboardHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissKeyboard()
                        }
                }
            }
            .scrollIndicators(.hidden)
            .onReceive(keyboardPublisher) { height in
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = height
                }
            }
        }
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
    /// Makes the view keyboard-aware by adding bottom spacing equal to keyboard height.
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }
}
