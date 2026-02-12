//
//  CenteredOverlayModifier.swift
//  VERACommonUI
//

import SwiftUI

/// A view modifier that displays content as a centered overlay with a dismissable background.
///
/// When applied, it shows a semi-transparent background that dismisses on tap,
/// while the content remains centered and blocks tap gestures from passing through.
///
/// ## Usage
/// ```swift
/// .centeredOverlay(isPresented: $showPicker) {
///     EmojiPickerView()
/// }
/// ```
public struct CenteredOverlayModifier<OverlayContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let overlayContent: () -> OverlayContent
    let backgroundOpacity: Double
    let animation: Animation?

    /// Creates a centered overlay modifier.
    /// - Parameters:
    ///   - isPresented: Binding to control visibility.
    ///   - backgroundOpacity: Opacity of the background overlay. Defaults to 0.3.
    ///   - animation: Animation for show/hide. Defaults to `.easeInOut(duration: 0.3)`.
    ///   - content: The content to show in the center.
    public init(
        isPresented: Binding<Bool>,
        backgroundOpacity: Double = 0.3,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder content: @escaping () -> OverlayContent
    ) {
        self._isPresented = isPresented
        self.backgroundOpacity = backgroundOpacity
        self.animation = animation
        self.overlayContent = content
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(backgroundOpacity)
                            .ignoresSafeArea()
                            .onTapGesture {
                                if let animation {
                                    withAnimation(animation) {
                                        isPresented = false
                                    }
                                } else {
                                    isPresented = false
                                }
                            }
                        overlayContent()
                            .contentShape(Rectangle())
                            .onTapGesture {}
                    }
                }
            }
            .animation(animation, value: isPresented)
    }
}

// MARK: - View Extension

extension View {
    /// Presents content as a centered overlay with a dismissable background.
    /// - Parameters:
    ///   - isPresented: Binding to control visibility.
    ///   - backgroundOpacity: Opacity of the background overlay. Defaults to 0.3.
    ///   - animation: Animation for show/hide. Defaults to `.easeInOut(duration: 0.3)`.
    ///   - content: The content to show in the center.
    /// - Returns: A view with the centered overlay modifier applied.
    public func centeredOverlay<Content: View>(
        isPresented: Binding<Bool>,
        backgroundOpacity: Double = 0.3,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            CenteredOverlayModifier(
                isPresented: isPresented,
                backgroundOpacity: backgroundOpacity,
                animation: animation,
                content: content
            )
        )
    }
}
