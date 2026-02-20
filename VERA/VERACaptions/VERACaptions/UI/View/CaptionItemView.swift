//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERACommonUI

/// Renders a single caption line showing the speaker's name and their text.
///
/// `CaptionItemView` displays the ``UICaptionItem/text`` `AttributedString`
/// (bold speaker name followed by regular-weight caption text) in white over
/// the translucent caption background.
///
/// ## Accessibility
/// - Combines children into a single accessibility element.
/// - Uses ``UICaptionItem/accessibilityLabel`` (e.g. *"Alice says: Hello!"*)
///   so VoiceOver reads a natural sentence.
///
/// ## Layout
/// - Left-aligned, multi-line.
/// - Wraps vertically (`fixedSize(horizontal: false, vertical: true)`) to
///   prevent text truncation.
///
/// - SeeAlso: ``UICaptionItem``, ``CaptionsView``
struct CaptionItemView: View {
    /// The caption item to render, including the pre-formatted attributed text.
    let caption: UICaptionItem

    var body: some View {
        Text(caption.text)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(caption.accessibilityLabel)
    }
}


// MARK: - Previews

#if DEBUG
    #Preview("Short Caption") {
        CaptionItemView(caption: .previewAlice)
            .padding()
            .background(Color.black.opacity(0.75))
    }

    #Preview("Long Caption") {
        CaptionItemView(caption: .previewLongText)
            .padding()
            .frame(maxWidth: 600)
            .background(Color.black.opacity(0.75))
    }

    #Preview("Multiple Captions") {
        VStack(alignment: .leading, spacing: 8) {
            CaptionItemView(caption: .previewAlice)
            CaptionItemView(caption: .previewBob)
            CaptionItemView(caption: .previewCharlie)
        }
        .padding()
        .background(Color.black.opacity(0.75))
    }
#endif
