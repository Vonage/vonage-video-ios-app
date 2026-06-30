//
//  Created by Vonage on 3/6/26.
//

import SwiftUI
import VERAFeedback

@main
struct VERAFeedbackDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                FeedbackSheetContent(
                  feedbackReportUseCase: NullFeedbackReportUseCase()
                )
            }
        }
    }
}
