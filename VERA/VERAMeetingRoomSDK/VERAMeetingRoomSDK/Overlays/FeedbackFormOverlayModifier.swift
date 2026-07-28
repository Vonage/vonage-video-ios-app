//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import VERAFeedback

struct FeedbackFormOverlayModifier: ViewModifier {
    @Environment(\.meetingRoomTheme) private var theme

    let isEnabled: Bool
    @Binding var showFeedbackForm: Bool
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showFeedbackForm) {
                    FeedbackSheetContent(
                        feedbackReportUseCase: container.feedbackFactory.makeFeedbackReportUseCase(),
                        sessionDebugInfoProvider: {
                            FeedbackSessionDebugInfo.fromCurrentCall(
                                in: container.sessionRepository
                            )
                        }
                    )
                    .presentationDetents([.large])
                    .opaquePresentationBackground(theme.background)
                }
        } else {
            content
        }
    }
}
