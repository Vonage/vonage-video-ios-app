import Foundation
import Testing

@testable import VERAFeedback

@MainActor
@Suite("Feedback Debug Dump Builder Tests")
struct FeedbackDebugDumpBuilderTests {

    @Test("debugDump includes platform and session sections")
    func debugDumpIncludesSections() {
        let dump = FeedbackDebugDumpBuilder.debugDump(
            session: FeedbackSessionDebugInfo(
                sessionId: "session-123",
                connectionId: "connection-456",
                connectionCreationTime: Date(timeIntervalSince1970: 0)
            )
        )

        #expect(dump.contains("==="))
        #expect(dump.contains("Session: session-123"))
        #expect(dump.contains("Connection: connection-456"))
        #expect(dump.contains("Connection creation time:"))
    }

    @Test("debugDump uses null placeholders when session info is missing")
    func debugDumpUsesNullPlaceholders() {
        let dump = FeedbackDebugDumpBuilder.debugDump()

        #expect(dump.contains("Session: null"))
        #expect(dump.contains("Connection: null"))
        #expect(dump.contains("Connection creation time: null"))
    }

    @Test("debugDump formats connection creation time as ISO8601")
    func debugDumpFormatsConnectionCreationTime() {
        let creationTime = Date(timeIntervalSince1970: 1_700_000_000.123)
        let dump = FeedbackDebugDumpBuilder.debugDump(
            session: FeedbackSessionDebugInfo(connectionCreationTime: creationTime)
        )

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        #expect(dump.contains("Connection creation time: \(formatter.string(from: creationTime))"))
    }

    @Test("FeedbackFormViewModel debugDump delegates to current session provider")
    func viewModelDebugDumpUsesProvider() {
        let viewModel = FeedbackTestHelpers.makeFormViewModel(
            sessionDebugInfoProvider: {
                FeedbackSessionDebugInfo(sessionId: "provided-session")
            }
        )

        let dump = viewModel.debugDump()
        #expect(dump.contains("Session: provided-session"))
    }
}
