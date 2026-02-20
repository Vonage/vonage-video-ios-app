//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERACommonUI

/// Layout constants for the captions overlay.
///
/// These values control spacing, sizing, and visual styling of the
/// translucent caption container displayed during a call.
private enum CaptionsViewConstants {
    /// Vertical spacing between individual caption items.
    static let itemSpacing: CGFloat = 8
    /// Inner padding around the caption list content.
    static let contentPadding: CGFloat = 12
    /// Maximum height of the scrollable caption area.
    static let maxHeight: CGFloat = 92
    /// Maximum width of the caption container (prevents over-stretching on iPad).
    static let maxWidth: CGFloat = 600
    /// Corner radius of the translucent background.
    static let cornerRadius: CGFloat = 12
    /// Opacity of the background fill.
    static let backgroundOpacity: Double = 0.75
    /// Horizontal padding from the screen edges.
    static let horizontalPadding: CGFloat = 16
    /// Duration of the auto-scroll animation when new captions arrive.
    static let scrollAnimationDuration: Double = 0.2
}

/// A stateless view that renders a scrollable list of live captions.
///
/// `CaptionsView` is a **presentational** component — it receives an array of
/// ``UICaptionItem`` values and renders them inside a vertically-scrolling,
/// translucent container. When new captions arrive the view auto-scrolls to
/// the latest entry. Multiple simultaneous speakers are supported.
///
/// ## Usage
///
/// Typically used through ``CaptionsViewContainer``, which manages the
/// ``CaptionsViewModel`` lifecycle (subscribe on appear, cancel on disappear).
///
/// ```swift
/// CaptionsView(captions: [
///     UICaptionItem(caption: CaptionItem(speakerName: "Alice", text: "Hello!"))
/// ])
/// ```
///
/// ## Layout
/// - Constrained to a maximum height of **92 pt** and width of **600 pt**.
/// - Rendered over a translucent rounded-rectangle background.
/// - Horizontally padded **16 pt** from the screen edges.
///
/// - SeeAlso: ``CaptionsViewContainer``, ``CaptionItemView``, ``UICaptionItem``
public struct CaptionsView: View {
    /// The caption items to display, ordered by the view model (newest last).
    public let captions: [UICaptionItem]

    /// Creates a captions view with the given items.
    ///
    /// - Parameter captions: The caption items to render. Defaults to an empty array.
    public init(captions: [UICaptionItem] = []) {
        self.captions = captions
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: CaptionsViewConstants.itemSpacing) {
                    ForEach(captions) { caption in
                        CaptionItemView(caption: caption)
                            .id(caption.id)
                    }
                }
                .padding(CaptionsViewConstants.contentPadding)
            }
            .frame(maxHeight: CaptionsViewConstants.maxHeight)
            .frame(maxWidth: CaptionsViewConstants.maxWidth)
            .background(
                RoundedRectangle(cornerRadius: CaptionsViewConstants.cornerRadius)
                    .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor.opacity(CaptionsViewConstants.backgroundOpacity))
            )
            .padding(.horizontal, CaptionsViewConstants.horizontalPadding)
            .onChange(of: captions.last?.id) { latestId in
                guard let latestId else { return }
                withAnimation(.easeOut(duration: CaptionsViewConstants.scrollAnimationDuration)) {
                    proxy.scrollTo(latestId, anchor: .bottom)
                }
            }.clipped()
        }
    }
}

// MARK: - Previews
#if DEBUG
    #Preview("1 Caption") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [.previewAlice])
            }
        }
    }

    #Preview("2 Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [.previewAlice, .previewBob])
            }
        }
    }

    #Preview("3 Captions") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [.previewAlice, .previewBob, .previewCharlie])
            }
        }
    }

    #Preview("6 Captions - Scrollable") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [
                    .previewAlice, .previewBob, .previewCharlie,
                    .previewDiana, .previewAlice2, .previewDiana2,
                ])
            }
        }
    }

    #Preview("Long Text") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [.previewLongText])
            }
        }
    }

    #Preview("Empty") {
        ZStack {
            Color.gray.ignoresSafeArea()
            VStack {
                Spacer()
                CaptionsView(captions: [])
            }
        }
    }
#endif
