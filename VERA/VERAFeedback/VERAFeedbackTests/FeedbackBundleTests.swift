import Foundation
import Testing

@testable import VERAFeedback

@Suite("Feedback bundle tests")
struct FeedbackBundleTests {

    @Test("veraFeedback bundle resolves")
    func veraFeedbackBundleResolves() {
        #expect(Bundle.veraFeedback.bundleIdentifier?.contains("VERAFeedback") == true)
    }
}
