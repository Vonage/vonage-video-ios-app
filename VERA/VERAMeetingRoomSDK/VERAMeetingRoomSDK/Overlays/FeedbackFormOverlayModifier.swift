//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERAFeedback

struct FeedbackFormOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showFeedbackForm: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackSheetContent()
                        .presentationDetents([.large])
                }
        } else {
            content
        }
    }
}
