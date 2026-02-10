//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERADomain

/// Displays a list of captions at the bottom of the screen
/// Supports multiple simultaneous speakers
public struct CaptionsView: View {
    /// Array of current captions to display
    public let captions: [CaptionItem]

    /// Maximum number of captions to display simultaneously
    private let maxVisibleCaptions = 3

    public init(captions: [CaptionItem]) {
        self.captions = captions
    }

    public var body: some View {
        VStack {
            Spacer()

            if !visibleCaptions.isEmpty {
                HStack {
                    Spacer()

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(visibleCaptions) { caption in
                            CaptionItemView(caption: caption)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.black.opacity(0.75))
                    )
                    .frame(maxWidth: 600)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    /// Returns the most recent captions up to the maximum visible limit
    private var visibleCaptions: [CaptionItem] {
        Array(
            captions
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(maxVisibleCaptions))
    }
}

#Preview("Single Caption") {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        CaptionsView(
            captions: [
                CaptionItem(
                    speakerName: "Alice",
                    text: "Hello everyone, welcome to the meeting!"
                )
            ]
        )
    }
}

#Preview("Multiple Captions") {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        CaptionsView(
            captions: [
                CaptionItem(
                    speakerName: "Alice",
                    text: "I agree with that proposal.",
                    timestamp: Date().addingTimeInterval(-2)
                ),
                CaptionItem(
                    speakerName: "Bob",
                    text: "Yes, let's move forward with the implementation.",
                    timestamp: Date().addingTimeInterval(-1)
                ),
                CaptionItem(
                    speakerName: "Charlie",
                    text: "Sounds good to me!"
                ),
            ]
        )
    }
}

#Preview("Long Caption") {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        CaptionsView(
            captions: [
                CaptionItem(
                    speakerName: "David",
                    text:
                        """
                        This is a very long caption that demonstrates how the view handles 
                        text that wraps across multiple lines and maintains good readability.
                        """
                )
            ]
        )
    }
}
