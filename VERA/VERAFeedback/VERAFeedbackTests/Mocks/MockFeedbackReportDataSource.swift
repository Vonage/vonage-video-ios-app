//
//  Created by Vonage on 11/06/2026.
//

import Foundation
@testable import VERAFeedback

final class MockFeedbackReportDataSource: FeedbackReportDataSource {
    var error: Error?
    var lastRequest: FeedbackReportDataSourceRequest?
    var response = FeedbackReportDataSourceResponse(
        message: "Report submitted",
        ticketUrl: "https://example.com/ticket/1",
        screenshotIncluded: false
    )

    func sendReport(
        _ request: FeedbackReportDataSourceRequest
    ) async throws -> FeedbackReportDataSourceResponse {
        lastRequest = request

        if let error {
            throw error
        }

        return response
    }
}
