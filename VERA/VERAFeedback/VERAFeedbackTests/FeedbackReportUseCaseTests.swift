//
//  Created by Vonage on 11/06/2026.
//

import Foundation
import Testing

@testable import VERAFeedback

@Suite("Feedback report use case tests")
struct FeedbackReportUseCaseTests {

    @Test func sendReportSucceeds() async throws {
        let sut = makeSUT()

        let result = try await sut(
            .init(
                title: "Screen share failed",
                name: "Alex",
                issue: "Video froze when sharing",
                image: nil,
                debugDump: "Session: abc"
            )
        )

        #expect(result.message == "Report submitted")
        #expect(result.ticketUrl == "https://example.com/ticket/1")
    }

    @Test func sendReportPassesCorrectValues() async throws {
        let dataSourceMock = MockFeedbackReportDataSource()
        let sut = makeSUT(feedbackReportDataSource: dataSourceMock)

        _ = try await sut(
            .init(
                title: "Screen share failed",
                name: "Alex",
                issue: "Video froze when sharing",
                image: nil,
                debugDump: "\nSession: abc\n"
            )
        )

        #expect(dataSourceMock.lastRequest?.title == "Screen share failed")
        #expect(dataSourceMock.lastRequest?.name == "Alex")
        #expect(dataSourceMock.lastRequest?.issue == "Video froze when sharing")
        #expect(dataSourceMock.lastRequest?.debugDump == "\nSession: abc\n")
    }

    @Test func sendReportPropagatesErrors() async throws {
        let dataSourceMock = MockFeedbackReportDataSource()
        dataSourceMock.error = URLError(.badServerResponse)
        let sut = makeSUT(feedbackReportDataSource: dataSourceMock)

        do {
            _ = try await sut(
                .init(
                    title: "Title",
                    name: "Name",
                    issue: "Issue",
                    image: nil,
                    debugDump: ""
                )
            )
            Issue.record("Should have thrown an error")
        } catch URLError.badServerResponse {
            // Expected
        } catch {
            Issue.record("Expected badServerResponse but got: \(error)")
        }
    }

    // MARK: - Test Helpers

    private func makeSUT(
        feedbackReportDataSource: any FeedbackReportDataSource = MockFeedbackReportDataSource()
    ) -> FeedbackReportUseCase {
        DefaultFeedbackReportUseCase(feedbackReportDataSource: feedbackReportDataSource)
    }
}
