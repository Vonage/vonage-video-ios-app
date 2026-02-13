//
//  DismissibleOverlayModifier.swift
//  VERACommonUI
//

import SwiftUI

/// A view modifier that displays content as a positioned overlay with a dismissible background.
///
/// When applied, it shows a semi-transparent background that dismisses on tap,
/// while the content remains at the specified alignment and blocks tap gestures from passing through.
///
/// ## Usage
/// ```swift
/// // Centered (default)
/// .dismissibleOverlay(isPresented: $showPicker) {
///     EmojiPickerView()
/// }
///
/// // Bottom with padding above bottom bar
/// .dismissibleOverlay(isPresented: $showPicker, alignment: .bottom, edgePadding: 80) {
///     EmojiPickerView()
/// }
/// ```
public struct DismissibleOverlayModifier<OverlayContent: View>: ViewModifier {

    @Binding var isPresented: Bool
    let overlayContent: () -> OverlayContent
    let backgroundOpacity: Double
    let animation: Animation?
    let alignment: Alignment
    let edgePadding: CGFloat

    /// Creates a dismissible overlay modifier.
    /// - Parameters:
    ///   - isPresented: Binding to control visibility.
    ///   - backgroundOpacity: Opacity of the background overlay. Defaults to 0.3.
    ///   - animation: Animation for show/hide. Defaults to `.easeInOut(duration: 0.3)`.
    ///   - alignment: The alignment of the overlay content. Defaults to `.center`.
    ///   - edgePadding: Padding applied to the edge based on alignment. Defaults to 0.
    ///   - content: The content to show in the overlay.
    public init(
        isPresented: Binding<Bool>,
        backgroundOpacity: Double = 0.3,
        animation: Animation? = .easeInOut(duration: 0.3),
        alignment: Alignment = .center,
        edgePadding: CGFloat = 0,
        @ViewBuilder content: @escaping () -> OverlayContent
    ) {
        self._isPresented = isPresented
        self.backgroundOpacity = backgroundOpacity
        self.animation = animation
        self.alignment = alignment
        self.edgePadding = edgePadding
        self.overlayContent = content
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack(alignment: alignment) {
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
                            .padding(paddingEdge, edgePadding)
                            .contentShape(Rectangle())
                            .onTapGesture {}
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .animation(animation, value: isPresented)
    }

    private var paddingEdge: Edge.Set {
        switch alignment {
        case .bottom, .bottomLeading, .bottomTrailing:
            return .bottom
        case .top, .topLeading, .topTrailing:
            return .top
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return []
        }
    }
}

// MARK: - View Extension

extension View {
    /// Presents content as a dismissible overlay with configurable positioning.
    /// - Parameters:
    ///   - isPresented: Binding to control visibility.
    ///   - alignment: The alignment of the overlay content. Defaults to `.center`.
    ///   - edgePadding: Padding applied to the edge based on alignment. Defaults to 0.
    ///   - backgroundOpacity: Opacity of the background overlay. Defaults to 0.3.
    ///   - animation: Animation for show/hide. Defaults to `.easeInOut(duration: 0.3)`.
    ///   - content: The content to show in the overlay.
    /// - Returns: A view with the dismissible overlay modifier applied.
    public func dismissibleOverlay<Content: View>(
        isPresented: Binding<Bool>,
        alignment: Alignment = .center,
        edgePadding: CGFloat = 0,
        backgroundOpacity: Double = 0.3,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(
            DismissibleOverlayModifier(
                isPresented: isPresented,
                backgroundOpacity: backgroundOpacity,
                animation: animation,
                alignment: alignment,
                edgePadding: edgePadding,
                content: content
            )
        )
    }
}
