//
//  Created by Vonage on 11/06/2026.
//

import Foundation

public struct FeedbackReportDataSourceRequest {
    public let title: String
    public let name: String
    public let issue: String
    public let image: PlatformImage?
    public let debugDump: String

    public init(
        title: String,
        name: String,
        issue: String,
        image: PlatformImage?,
        debugDump: String
    ) {
        self.title = title
        self.name = name
        self.issue = issue
        self.image = image
        self.debugDump = debugDump
    }
}

public struct FeedbackReportDataSourceResponse {
    public let message: String
    public let ticketUrl: String
    public let screenshotIncluded: Bool?

    public init(message: String, ticketUrl: String, screenshotIncluded: Bool?) {
        self.message = message
        self.ticketUrl = ticketUrl
        self.screenshotIncluded = screenshotIncluded
    }
}

public protocol FeedbackReportDataSource {
    func sendReport(
        _ request: FeedbackReportDataSourceRequest
    ) async throws -> FeedbackReportDataSourceResponse
}
