//
//  Created by Vonage on 5/2/26.
//

import SwiftUI
import VERACommonUI

private enum CaptionsViewConstants {
    static let itemSpacing: CGFloat = 8
    static let contentPadding: CGFloat = 12
    static let maxHeight: CGFloat = 92
    static let maxWidth: CGFloat = 600
    static let cornerRadius: CGFloat = 12
    static let backgroundOpacity: Double = 0.75
    static let horizontalPadding: CGFloat = 16
    static let scrollAnimationDuration: Double = 0.2
}

/// Displays a list of captions at the bottom of the screen
/// Supports multiple simultaneous speakers
public struct CaptionsView: View {
    /// Array of current captions to display
    public let captions: [UICaptionItem]
    
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
                .previewDiana, .previewAlice2, .previewDiana2
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
