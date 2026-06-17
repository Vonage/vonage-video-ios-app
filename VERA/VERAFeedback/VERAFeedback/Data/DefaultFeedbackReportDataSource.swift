//
//  Created by Vonage on 11/06/2026.
//

import Foundation
import VERADomain

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

private struct FeedbackReportDataRequest: Encodable {
    let title: String
    let name: String
    let issue: String
    let attachment: String
}

private struct FeedbackReportResponse: Decodable {
    let feedbackData: FeedbackReportResponseData
}

private struct FeedbackReportResponseData: Decodable {
    let message: String
    let ticketUrl: String
    let screenshotIncluded: Bool?
}

public struct DefaultFeedbackReportDataSource: FeedbackReportDataSource {
    private let baseURL: URL
    private let httpClient: HTTPClient

    public init(
        baseURL: URL,
        httpClient: HTTPClient
    ) {
        self.baseURL = baseURL
        self.httpClient = httpClient
    }

    public func sendReport(
        _ request: FeedbackReportDataSourceRequest
    ) async throws -> FeedbackReportDataSourceResponse {
        let url = baseURL.appendingPathComponent("feedback/report")
        let body = try JSONEncoder().encode(
            FeedbackReportDataRequest(
                title: request.title,
                name: request.name,
                issue: request.issue + request.debugDump,
                attachment: FeedbackImageEncoder.encodeToBase64(request.image)
            )
        )

        let data = try await httpClient.post(url, data: body)
        let responseData = try JSONDecoder().decode(FeedbackReportResponse.self, from: data).feedbackData

        return FeedbackReportDataSourceResponse(
            message: responseData.message,
            ticketUrl: responseData.ticketUrl,
            screenshotIncluded: responseData.screenshotIncluded
        )
    }
}
