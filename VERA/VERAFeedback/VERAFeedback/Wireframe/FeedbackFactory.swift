//
//  Created by Vonage on 08/06/2026.
//

import Foundation
import VERADomain

public final class FeedbackFactory {

    private let feedbackReportDataSource: FeedbackReportDataSource

    public init(
        baseURL: URL,
        httpClient: HTTPClient,
        feedbackReportDataSource: (any FeedbackReportDataSource)? = nil
    ) {
        self.feedbackReportDataSource = feedbackReportDataSource ?? DefaultFeedbackReportDataSource(
            baseURL: baseURL,
            httpClient: httpClient
        )
    }

    public func makeFeedbackReportUseCase() -> FeedbackReportUseCase {
        DefaultFeedbackReportUseCase(feedbackReportDataSource: feedbackReportDataSource)
    }

    /// Creates the feedback button for the meeting room bottom bar.
    ///
    /// - Parameter onShowFeedbackForm: Closure fired when the button is tapped.
    ///   The caller is responsible for presenting the feedback sheet.
    @MainActor
    public func makeMeetingRoomButton(onShowFeedbackForm: @escaping () -> Void) -> FeedbackComponentButton {
        .init(onShowFeedbackForm: onShowFeedbackForm)
    }
}
