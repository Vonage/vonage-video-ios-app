//
//  Created by Vonage on 11/06/2026.
//

import Foundation

public struct FeedbackReportRequest {
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

public typealias FeedbackReportResult = FeedbackReportDataSourceResponse

public protocol FeedbackReportUseCase {
    func callAsFunction(_ request: FeedbackReportRequest) async throws -> FeedbackReportResult
}

public final class DefaultFeedbackReportUseCase: FeedbackReportUseCase {
    private let feedbackReportDataSource: any FeedbackReportDataSource

    public init(feedbackReportDataSource: any FeedbackReportDataSource) {
        self.feedbackReportDataSource = feedbackReportDataSource
    }

    public func callAsFunction(
        _ request: FeedbackReportRequest
    ) async throws -> FeedbackReportResult {
        let dataSourceRequest = FeedbackReportDataSourceRequest(
            title: request.title,
            name: request.name,
            issue: request.issue,
            image: request.image,
            debugDump: request.debugDump
        )
        return try await feedbackReportDataSource.sendReport(dataSourceRequest)
    }
}

public final class NullFeedbackReportUseCase: FeedbackReportUseCase {
    public init() {}

    public func callAsFunction(
        _ request: FeedbackReportRequest
    ) async throws -> FeedbackReportResult {
        .init(message: "", ticketUrl: "", screenshotIncluded: nil)
    }
}
