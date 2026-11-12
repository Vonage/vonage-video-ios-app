import Testing
import VERAFeedback

@Suite("Feedback result value transfer")
struct FeedbackResultTransferTests {
    @Test("Feedback results retain all fields and optional screenshot status across tasks and an actor")
    func transfer() async {
        let results = [
            FeedbackReportDataSourceResponse(message: "", ticketUrl: "", screenshotIncluded: nil),
            FeedbackReportDataSourceResponse(
                message: "Created", ticketUrl: "https://support.invalid/ticket/1", screenshotIncluded: true),
            FeedbackReportDataSourceResponse(
                message: "返信 📷", ticketUrl: "https://support.invalid/会議", screenshotIncluded: false),
        ]
        let transferred = await Task.detached { results }.value
        let storage = FeedbackResultStorage()
        for (result, expected) in zip(transferred, results) {
            await storage.store(result)
            let received = await storage.result
            #expect(received?.message == expected.message)
            #expect(received?.ticketUrl == expected.ticketUrl)
            #expect(received?.screenshotIncluded == expected.screenshotIncluded)
        }
    }

    @Test("Replacing a result preserves an earlier snapshot and the public result alias")
    func snapshots() async {
        let first: FeedbackReportResult = .init(message: "first", ticketUrl: "first", screenshotIncluded: nil)
        let second: FeedbackReportResult = .init(message: "second", ticketUrl: "second", screenshotIncluded: true)
        let storage = FeedbackResultStorage()
        await storage.store(first)
        let snapshot = await storage.result
        await storage.store(second)
        let latest = await storage.result
        #expect(snapshot?.message == "first")
        #expect(snapshot?.ticketUrl == "first")
        #expect(snapshot?.screenshotIncluded == nil)
        #expect(latest?.message == "second")
        #expect(latest?.ticketUrl == "second")
        #expect(latest?.screenshotIncluded == true)
    }
}

private actor FeedbackResultStorage {
    private(set) var result: FeedbackReportDataSourceResponse?

    func store(_ value: FeedbackReportDataSourceResponse) {
        result = value
    }
}
