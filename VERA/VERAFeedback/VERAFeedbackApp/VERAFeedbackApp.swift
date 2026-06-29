//
//  Created by Vonage on 3/6/26.
//

import SwiftUI
import VERAFeedback

@main
struct VERAFeedbackDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoMeetingView()
        }
    }
}

private struct DemoMeetingView: View {
    @State private var isShowingFeedback = false
    private let feedbackReportUseCase = DemoFeedbackReportUseCase()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.teal, .indigo, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Feedback Demo")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Simulated meeting room")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                FeedbackComponentButton {
                    isShowingFeedback = true
                }
                .padding(.bottom, 32)
            }
            .padding()
        }
        .sheet(isPresented: $isShowingFeedback) {
            FeedbackSheetContent(
                feedbackReportUseCase: feedbackReportUseCase,
                sessionDebugInfoProvider: DemoFeedbackSessionDebugInfoProvider.make
            )
        }
    }
}

private final class DemoFeedbackReportUseCase: FeedbackReportUseCase {
    func callAsFunction(_ request: FeedbackReportRequest) async throws -> FeedbackReportResult {
        try await Task.sleep(nanoseconds: 600_000_000)

        return FeedbackReportDataSourceResponse(
            message: "Demo report submitted",
            ticketUrl: "https://example.com/demo-feedback/VIDSOL-123",
            screenshotIncluded: request.image != nil
        )
    }
}

private enum DemoFeedbackSessionDebugInfoProvider {
    static func make() -> FeedbackSessionDebugInfo {
        FeedbackSessionDebugInfo(
            sessionId: "demo-session-123",
            connectionId: "demo-connection-456",
            connectionCreationTime: Date(timeIntervalSince1970: 1_718_000_000)
        )
    }
}

#Preview {
    DemoMeetingView()
}
