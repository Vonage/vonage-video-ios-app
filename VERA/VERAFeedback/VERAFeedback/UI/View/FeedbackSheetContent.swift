//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI

public struct FeedbackSheetContent: View {
    @StateObject private var feedbackFormViewModel: FeedbackFormViewModel

    public init(
        feedbackReportUseCase: FeedbackReportUseCase,
        sessionDebugInfoProvider: @escaping () -> FeedbackSessionDebugInfo = { .empty }
    ) {
        _feedbackFormViewModel = StateObject(
            wrappedValue: FeedbackFormViewModel(
                feedbackReportUseCase: feedbackReportUseCase,
                sessionDebugInfoProvider: sessionDebugInfoProvider
            )
        )
    }

    public var body: some View {
        FeedbackView(feedbackFormViewModel: feedbackFormViewModel)
    }
}
