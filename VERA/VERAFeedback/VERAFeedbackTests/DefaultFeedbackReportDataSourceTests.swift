import Foundation
import Testing
import VERATestHelpers

@testable import VERAFeedback

@MainActor
@Suite("DefaultFeedbackReportDataSource Tests")
struct DefaultFeedbackReportDataSourceTests {

    @Test("sendReport posts correct JSON body and user-agent header")
    func sendReportPostsCorrectBodyAndHeader() async throws {
        let httpClient = MockHTTPClient()
        let baseURL = URL(string: "http://example.com")!
        let sut = DefaultFeedbackReportDataSource(baseURL: baseURL, httpClient: httpClient)

        // Prepare a valid server response
        let serverJSON: [String: Any] = [
            "feedbackData": [
                "message": "Report submitted",
                "ticketUrl": "https://example.com/ticket/1",
                "screenshotIncluded": false,
            ]
        ]
        let responseData = try JSONSerialization.data(withJSONObject: serverJSON)
        httpClient.data = responseData

        let request = FeedbackReportDataSourceRequest(
            title: "T",
            name: "N",
            issue: "I",
            image: nil,
            debugDump: "DEBUG"
        )

        let result = try await sut.sendReport(request)

        // Assert response mapping
        #expect(result.message == "Report submitted")
        #expect(result.ticketUrl == "https://example.com/ticket/1")

        // Assert HTTP client got correct URL
        #expect(httpClient.recordedURL.absoluteString == "http://example.com/feedback/report")

        // Assert posted body contains concatenated issue + debugDump and empty attachment
        guard let recorded = httpClient.recordedData else {
            Issue.record("No recorded body data")
            return
        }

        let decoded = try JSONSerialization.jsonObject(with: recorded) as? [String: Any]
        #expect((decoded?["title"] as? String) == "T")
        #expect((decoded?["name"] as? String) == "N")
        #expect((decoded?["issue"] as? String) == "IDEBUG")
        #expect((decoded?["attachment"] as? String) == "")

        // User-Agent header should be present; appVersion defaults to "—"
        #expect(httpClient.recordedHeaders["User-Agent"]?.starts(with: "VeraNativeiOS/") == true)
    }

    @Test("sendReport parses screenshotIncluded flag from server")
    func sendReportParsesScreenshotIncluded() async throws {
        let httpClient = MockHTTPClient()
        let baseURL = URL(string: "http://example.com")!
        let sut = DefaultFeedbackReportDataSource(baseURL: baseURL, httpClient: httpClient)

        let serverJSON: [String: Any] = [
            "feedbackData": [
                "message": "OK",
                "ticketUrl": "https://example.com/t/2",
                "screenshotIncluded": true,
            ]
        ]
        httpClient.data = try JSONSerialization.data(withJSONObject: serverJSON)

        let request = FeedbackReportDataSourceRequest(
            title: "T",
            name: "N",
            issue: "I",
            image: nil,
            debugDump: ""
        )

        let result = try await sut.sendReport(request)
        #expect(result.screenshotIncluded == true)
    }

    @Test("sendReport propagates HTTP client errors")
    func sendReportPropagatesErrors() async throws {
        let httpClient = MockHTTPClient()
        httpClient.shouldThrowError = true
        let baseURL = URL(string: "http://example.com")!
        let sut = DefaultFeedbackReportDataSource(baseURL: baseURL, httpClient: httpClient)

        let request = FeedbackReportDataSourceRequest(
            title: "T",
            name: "N",
            issue: "I",
            image: nil,
            debugDump: ""
        )

        await #expect(throws: (any Error).self) {
            try await sut.sendReport(request)
        }
    }

    @Test("sendReport includes base64 attachment when image is provided")
    func sendReportIncludesBase64Attachment() async throws {
        let httpClient = MockHTTPClient()
        let baseURL = URL(string: "http://example.com")!
        let sut = DefaultFeedbackReportDataSource(baseURL: baseURL, httpClient: httpClient)

        let serverJSON: [String: Any] = [
            "feedbackData": [
                "message": "OK",
                "ticketUrl": "https://example.com/ticket/3",
                "screenshotIncluded": true,
            ]
        ]
        httpClient.data = try JSONSerialization.data(withJSONObject: serverJSON)

        let request = FeedbackReportDataSourceRequest(
            title: "T",
            name: "N",
            issue: "I",
            image: FeedbackTestHelpers.makeTestImage(),
            debugDump: ""
        )

        _ = try await sut.sendReport(request)

        guard let recorded = httpClient.recordedData,
            let decoded = try JSONSerialization.jsonObject(with: recorded) as? [String: Any],
            let attachment = decoded["attachment"] as? String
        else {
            Issue.record("Expected attachment in request body")
            return
        }

        #expect(!attachment.isEmpty)
        #expect(Data(base64Encoded: attachment) != nil)
    }

    @Test("sendReport throws when server response cannot be decoded")
    func sendReportThrowsOnInvalidResponse() async {
        let httpClient = MockHTTPClient()
        httpClient.data = Data("{}".utf8)
        let sut = DefaultFeedbackReportDataSource(
            baseURL: URL(string: "http://example.com")!,
            httpClient: httpClient
        )

        let request = FeedbackReportDataSourceRequest(
            title: "T",
            name: "N",
            issue: "I",
            image: nil,
            debugDump: ""
        )

        await #expect(throws: (any Error).self) {
            try await sut.sendReport(request)
        }
    }
}
