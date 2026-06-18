//
//  Created by Vonage on 18/06/2026.
//

import Foundation

@testable import VERAFeedback

final class MockFeedbackReportUseCase: FeedbackReportUseCase {
    var error: Error?
    var lastRequest: FeedbackReportRequest?
    var delayNanoseconds: UInt64 = 0
    var response = FeedbackReportDataSourceResponse(
        message: "Report submitted",
        ticketUrl: "https://example.com/ticket/1",
        screenshotIncluded: false
    )

    func callAsFunction(_ request: FeedbackReportRequest) async throws -> FeedbackReportResult {
        lastRequest = request

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        if let error {
            throw error
        }

        return response
    }
}
