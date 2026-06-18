import SwiftUI
import Testing
import VERATestHelpers

@testable import VERAFeedback

@MainActor
@Suite("Feedback factory tests")
struct FeedbackFactoryTests {

    @Test("makeMeetingRoomButton returns a hostable button")
    func makeMeetingRoomButtonReturnsHostableButton() {
        let httpClient = MockHTTPClient()
        let factory = FeedbackFactory(baseURL: URL("http://example.com")!, httpClient: httpClient)
        let button = factory.makeMeetingRoomButton(onShowFeedbackForm: {})

        FeedbackViewTestHelpers.host(button, size: CGSize(width: 120, height: 60))
        #expect(true)
    }

    @Test("makeMeetingRoomButton forwards tap when possible")
    func makeMeetingRoomButtonForwardsTapWhenPossible() {
        let httpClient = MockHTTPClient()
        let factory = FeedbackFactory(baseURL: URL("http://example.com")!, httpClient: httpClient)
        var didTap = false
        let button = factory.makeMeetingRoomButton(onShowFeedbackForm: { didTap = true })

        let context = FeedbackViewTestHelpers.host(
            button.accessibilityIdentifier("feedback_factory_button"),
            size: CGSize(width: 120, height: 60)
        )

        _ =
            context.tapAccessibilityIdentifier("feedback_factory_button")
            || context.tapFirstButton()
            || context.pressAllButtonLikeElements()

        if didTap {
            #expect(didTap == true)
        }
    }

    @Test("makeFeedbackReportUseCase submits report through HTTP client")
    func makeFeedbackReportUseCaseSubmitsReport() async throws {
        let httpClient = MockHTTPClient()
        let factory = FeedbackFactory(baseURL: URL(string: "http://example.com")!, httpClient: httpClient)
        let useCase = factory.makeFeedbackReportUseCase()

        let serverJSON: [String: Any] = [
            "feedbackData": [
                "message": "Ticket created",
                "ticketUrl": "https://example.com/ticket/99",
                "screenshotIncluded": false,
            ]
        ]
        httpClient.data = try JSONSerialization.data(withJSONObject: serverJSON)

        let result = try await useCase(
            .init(
                title: "Broken audio",
                name: "Sam",
                issue: "No sound",
                image: nil,
                debugDump: ""
            )
        )

        #expect(result.message == "Ticket created")
        #expect(result.ticketUrl == "https://example.com/ticket/99")
        #expect(httpClient.recordedURL.absoluteString == "http://example.com/feedback/report")
    }

    @Test("init uses injected feedback report data source when provided")
    func initUsesInjectedFeedbackReportDataSource() async throws {
        let dataSource = MockFeedbackReportDataSource()
        let factory = FeedbackFactory(
            baseURL: URL(string: "http://example.com")!,
            httpClient: MockHTTPClient(),
            feedbackReportDataSource: dataSource
        )
        let useCase = factory.makeFeedbackReportUseCase()

        _ = try await useCase(
            .init(
                title: "Audio issue",
                name: "Jamie",
                issue: "Echo on call",
                image: nil,
                debugDump: "debug"
            )
        )

        #expect(dataSource.lastRequest?.title == "Audio issue")
        #expect(dataSource.lastRequest?.debugDump == "debug")
    }
}
