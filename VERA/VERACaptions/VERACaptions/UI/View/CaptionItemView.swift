//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERACommonUI

/// Displays a single caption with speaker name and text
struct CaptionItemView: View {
    let caption: UICaptionItem

    var body: some View {
        Text(caption.text)
            .adaptiveFont(.bodyBase)
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
