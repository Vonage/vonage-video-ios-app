//
//  Created by Vonage on 10/10/25.
//

import Combine
import SwiftUI
import VERACaptions
@preconcurrency import VERADomain

@main
struct VERACaptionsApp: App {

    var body: some Scene {
        WindowGroup {
            CaptionsDemoView()
        }
    }
}

// MARK: - Demo View

struct CaptionsDemoView: View {
    @StateObject private var buttonViewModel: CaptionsButtonViewModel
    @StateObject private var captionsViewModel: CaptionsViewModel

    private let repository: CaptionsRepository
    private let statusDataSource: DefaultCaptionsStatusDataSource

    init() {
        let repository = DefaultCaptionsRepository()
        let statusDataSource = DefaultCaptionsStatusDataSource()
        let activationDataSource = DemoCaptionsActivationDataSource(
            statusDataSource: statusDataSource,
            repository: repository
        )

        let factory = CaptionsFactory(
            captionsActivationDataSource: activationDataSource,
            captionsStatusDataSource: statusDataSource,
            captionsRepository: repository
        )

        let captionsResult = factory.makeCaptionsView()
        let buttonResult = factory.makeCaptionsButton(roomName: "demo-room")

        self.repository = repository
        self.statusDataSource = statusDataSource
        _captionsViewModel = StateObject(wrappedValue: captionsResult.viewModel)
        _buttonViewModel = StateObject(wrappedValue: buttonResult.viewModel)
    }

    var body: some View {
        ZStack {
            background

            VStack {
                header
                Spacer()
                CaptionsViewContainer(viewModel: captionsViewModel)
                bottomBar
            }
        }
    }

    // MARK: - Subviews

    private var background: some View {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        Text("Captions Demo")
            .font(.title)
            .foregroundStyle(.white)
            .padding()
    }

    private var bottomBar: some View {
        CaptionsButtonContainer(viewModel: buttonViewModel)
            .padding(.bottom, 16)
    }
}

// MARK: - Demo Activation Data Source

/// A mock data source that simulates enabling/disabling captions.
/// When captions are enabled, it starts a timer that feeds demo captions
/// into the shared repository, creating a self-contained loopback.
private final class DemoCaptionsActivationDataSource: CaptionsActivationDataSource, @unchecked Sendable {

    private let statusDataSource: CaptionsStatusDataSource
    private let repository: CaptionsRepository
    private var timer: Timer?
    private var currentIndex = 0

    private let demoMessages: [(speaker: String, text: String)] = [
        ("Alice", "Hello everyone, welcome to today's meeting!"),
        ("Bob", "Thanks for joining, let's get started."),
        ("Charlie", "I have a few updates to share."),
        ("Alice", "Great! Let's hear them."),
        ("Bob", "First, the project is progressing well."),
        ("Charlie", "We've completed the initial phase ahead of schedule."),
        ("Alice", "That's excellent news!"),
        ("Bob", "The team has done an amazing job."),
        ("Charlie", "Next, we need to discuss the upcoming milestones."),
        ("Alice", "I agree, let's review the timeline."),
        ("Bob", "The deadline for phase two is next month."),
        ("Charlie", "We should be able to meet that deadline."),
        ("Alice", "Let's make sure we stay on track."),
        ("Bob", "I'll set up a follow-up meeting for next week."),
        ("Charlie", "Sounds good. Any other topics?"),
        ("Alice", "That's all for now, thanks everyone!"),
    ]

    init(
        statusDataSource: CaptionsStatusDataSource,
        repository: CaptionsRepository
    ) {
        self.statusDataSource = statusDataSource
        self.repository = repository
    }

    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse {
        let captionsId = "demo-captions-\(UUID().uuidString.prefix(8))"
        startFeedingCaptions()
        return EnableCaptionsDataSourceResponse(captionsId: captionsId)
    }

    // MARK: - Private

    private func startFeedingCaptions() {
        currentIndex = 0
        var activeCaptions: [CaptionItem] = []

        Task { @MainActor in
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
                guard let self else { return }

                guard self.currentIndex < self.demoMessages.count else {
                    self.currentIndex = 0
                    activeCaptions = []
                    return
                }

                let message = self.demoMessages[self.currentIndex]
                let caption = CaptionItem(
                    speakerName: message.speaker,
                    text: message.text
                )

                activeCaptions.append(caption)

                // Keep only last 5 captions in the buffer
                if activeCaptions.count > 5 {
                    activeCaptions.removeFirst()
                }

                let captionsToSend = activeCaptions
                Task {
                    await self.repository.updateCaptions(captionsToSend)
                }

                self.currentIndex += 1
            }
        }
    }

    @MainActor
    private func stopFeedingCaptions() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview {
    CaptionsDemoView()
}
