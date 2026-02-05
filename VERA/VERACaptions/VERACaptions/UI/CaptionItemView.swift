//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERACommonUI

/// Displays a single caption with speaker name and text
struct CaptionItemView: View {
    let caption: CaptionItem

    var body: some View {
        Text(caption.speakerName + ": " + caption.text)
            .adaptiveFont(.bodyBase)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(caption.speakerName) says: \(caption.text)")
    }
}

#Preview {
    VStack {
        Spacer()

        CaptionItemView(
            caption: CaptionItem(
                speakerName: "John Doe",
                text: "This is a sample caption that demonstrates how the caption view looks with a longer text."
            )
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray)
}
