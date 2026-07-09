//
//  Created by Vonage on 20/06/2026.
//

import SwiftUI

/// Describes which edges of a horizontal scroll view should fade and where the fade should end.
///
/// The state is intentionally pure so the scroll affordance logic can be tested without rendering
/// SwiftUI views. It is used by ``HorizontalScrollAffordanceMaskModifier`` to build the mask gradient.
struct HorizontalScrollAffordanceMaskState {
    /// Whether the leading edge should fade because there are hidden items before the visible range.
    let leadingFade: Bool
    /// Whether the trailing edge should fade because there are hidden items after the visible range.
    let trailingFade: Bool
    /// The normalized gradient stop where the leading fade becomes fully opaque.
    let leadingStop: CGFloat
    /// The normalized gradient stop where the trailing fade starts becoming transparent.
    let trailingStop: CGFloat

    /// Creates a resolved mask state.
    /// - Parameters:
    ///   - leadingFade: Whether the leading edge should fade.
    ///   - trailingFade: Whether the trailing edge should fade.
    ///   - leadingStop: The normalized stop where leading opacity reaches full strength.
    ///   - trailingStop: The normalized stop where trailing opacity starts fading out.
    init(
        leadingFade: Bool,
        trailingFade: Bool,
        leadingStop: CGFloat,
        trailingStop: CGFloat
    ) {
        self.leadingFade = leadingFade
        self.trailingFade = trailingFade
        self.leadingStop = leadingStop
        self.trailingStop = trailingStop
    }

    /// Resolves fade visibility and gradient stops from scroll measurements.
    /// - Parameters:
    ///   - isEnabled: Whether the affordance should be applied.
    ///   - visibleWidth: The width of the visible scroll viewport.
    ///   - contentWidth: The full intrinsic width of the scroll content.
    ///   - scrollOffset: The current horizontal scroll offset, measured from the leading edge.
    ///   - fadeWidth: The desired fade width in points.
    ///   - tolerance: The minimum hidden distance needed before a fade is shown.
    /// - Returns: A mask state describing leading/trailing fade visibility and gradient stops.
    static func resolve(
        isEnabled: Bool,
        visibleWidth: CGFloat,
        contentWidth: CGFloat,
        scrollOffset: CGFloat,
        fadeWidth: CGFloat,
        tolerance: CGFloat
    ) -> HorizontalScrollAffordanceMaskState {
        let hasLeadingHiddenItems = scrollOffset > tolerance
        let hasTrailingHiddenItems = contentWidth - visibleWidth - scrollOffset > tolerance

        return HorizontalScrollAffordanceMaskState(
            leadingFade: isEnabled && hasLeadingHiddenItems,
            trailingFade: isEnabled && hasTrailingHiddenItems,
            leadingStop: visibleWidth > 0 ? min(fadeWidth / visibleWidth, 0.5) : 0,
            trailingStop: visibleWidth > 0 ? max(1 - fadeWidth / visibleWidth, 0.5) : 1
        )
    }
}

/// Applies a horizontal mask that fades scroll content only on edges with hidden items.
///
/// This modifier does not draw an overlay or intercept touches. Instead, it masks the content itself,
/// making clipped content fade naturally at the leading and/or trailing edge.
struct HorizontalScrollAffordanceMaskModifier: ViewModifier {
    /// Whether the scroll affordance is enabled.
    let isEnabled: Bool
    /// The width of the visible scroll viewport.
    let visibleWidth: CGFloat
    /// The full intrinsic width of the scroll content.
    let contentWidth: CGFloat
    /// The current horizontal scroll offset, measured from the leading edge.
    let scrollOffset: CGFloat
    /// The desired fade width in points.
    let fadeWidth: CGFloat
    /// The minimum hidden distance needed before a fade is shown.
    let tolerance: CGFloat

    /// Creates a horizontal scroll affordance mask modifier.
    /// - Parameters:
    ///   - isEnabled: Whether the affordance should be applied.
    ///   - visibleWidth: The width of the visible scroll viewport.
    ///   - contentWidth: The full intrinsic width of the scroll content.
    ///   - scrollOffset: The current horizontal scroll offset, measured from the leading edge.
    ///   - fadeWidth: The desired fade width in points.
    ///   - tolerance: The minimum hidden distance needed before a fade is shown.
    init(
        isEnabled: Bool,
        visibleWidth: CGFloat,
        contentWidth: CGFloat,
        scrollOffset: CGFloat,
        fadeWidth: CGFloat,
        tolerance: CGFloat
    ) {
        self.isEnabled = isEnabled
        self.visibleWidth = visibleWidth
        self.contentWidth = contentWidth
        self.scrollOffset = scrollOffset
        self.fadeWidth = fadeWidth
        self.tolerance = tolerance
    }

    private var state: HorizontalScrollAffordanceMaskState {
        HorizontalScrollAffordanceMaskState.resolve(
            isEnabled: isEnabled,
            visibleWidth: visibleWidth,
            contentWidth: contentWidth,
            scrollOffset: scrollOffset,
            fadeWidth: fadeWidth,
            tolerance: tolerance
        )
    }

    /// Builds the masked view content.
    /// - Parameter content: The view content to mask.
    /// - Returns: The content masked with the horizontal scroll affordance gradient.
    func body(content: Content) -> some View {
        content.mask(mask)
    }

    private var mask: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(state.leadingFade ? 0 : 1), location: 0),
                .init(color: .black, location: state.leadingStop),
                .init(color: .black, location: state.trailingStop),
                .init(color: .black.opacity(state.trailingFade ? 0 : 1), location: 1),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// Stores the visible width measured for the horizontal emoji picker viewport.
struct EmojiHorizontalPickerVisibleWidthKey: PreferenceKey {
    /// The default measured visible width before layout reports a value.
    static let defaultValue: CGFloat = 0

    /// Keeps the largest reported visible width during a layout pass.
    /// - Parameters:
    ///   - value: The accumulated visible width.
    ///   - nextValue: The next measured visible width.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Stores the intrinsic content width measured for the horizontal emoji picker.
struct EmojiHorizontalPickerContentWidthKey: PreferenceKey {
    /// The default measured content width before layout reports a value.
    static let defaultValue: CGFloat = 0

    /// Keeps the largest reported content width during a layout pass.
    /// - Parameters:
    ///   - value: The accumulated content width.
    ///   - nextValue: The next measured content width.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Stores the content offset measured inside the horizontal picker coordinate space.
struct EmojiHorizontalPickerScrollOffsetKey: PreferenceKey {
    /// The default scroll offset before layout reports a value.
    static let defaultValue: CGFloat = 0

    /// Stores the latest measured scroll offset.
    /// - Parameters:
    ///   - value: The accumulated scroll offset.
    ///   - nextValue: The next measured scroll offset.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Applies a horizontal mask that fades the edges only when scroll content is hidden.
    /// - Parameters:
    ///   - isEnabled: Whether the affordance should be applied.
    ///   - visibleWidth: The width of the visible scroll viewport.
    ///   - contentWidth: The full intrinsic width of the scroll content.
    ///   - scrollOffset: The current horizontal scroll offset, measured from the leading edge.
    ///   - fadeWidth: The desired fade width in points.
    ///   - tolerance: The minimum hidden distance needed before a fade is shown.
    /// - Returns: A view masked with the horizontal scroll affordance.
    func horizontalScrollAffordanceMask(
        isEnabled: Bool,
        visibleWidth: CGFloat,
        contentWidth: CGFloat,
        scrollOffset: CGFloat,
        fadeWidth: CGFloat,
        tolerance: CGFloat
    ) -> some View {
        modifier(
            HorizontalScrollAffordanceMaskModifier(
                isEnabled: isEnabled,
                visibleWidth: visibleWidth,
                contentWidth: contentWidth,
                scrollOffset: scrollOffset,
                fadeWidth: fadeWidth,
                tolerance: tolerance
            )
        )
    }

    /// Measures the visible width of the view and writes it to ``EmojiHorizontalPickerVisibleWidthKey``.
    /// - Returns: A view that reports its visible width through a preference key.
    func readEmojiHorizontalPickerVisibleWidth() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: EmojiHorizontalPickerVisibleWidthKey.self,
                    value: proxy.size.width
                )
            }
        }
    }

    /// Measures the intrinsic content width and writes it to ``EmojiHorizontalPickerContentWidthKey``.
    /// - Returns: A view that reports its content width through a preference key.
    func readEmojiHorizontalPickerContentWidth() -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: EmojiHorizontalPickerContentWidthKey.self,
                    value: proxy.size.width
                )
            }
        }
    }

    /// Measures the horizontal offset of the view in a named coordinate space.
    /// - Parameter coordinateSpace: The coordinate space used by the containing scroll view.
    /// - Returns: A view that reports its minX position through a preference key.
    func readEmojiHorizontalPickerScrollOffset(in coordinateSpace: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: EmojiHorizontalPickerScrollOffsetKey.self,
                    value: proxy.frame(in: .named(coordinateSpace)).minX
                )
            }
        }
    }
}
