//
//  Created by Vonage on 10/2/26.
//

import SwiftUI
import VERAReactions

@main
struct VERAReactionsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoReactionsView()
        }
    }
}

// MARK: - Demo View

/// A full-featured demo that wires the emoji button, picker, and floating overlay
/// together through a shared repository — picking an emoji makes it float on screen.
struct DemoReactionsView: View {

    @StateObject private var buttonViewModel: EmojiButtonContainerViewModel
    @StateObject private var overlayViewModel: FloatingEmojisOverlayViewModel

    init() {
        let repository = DefaultReactionsRepository()
        let useCase = DemoSendReactionUseCase(repository: repository)

        _buttonViewModel = StateObject(
            wrappedValue: EmojiButtonContainerViewModel(
                sendReactionUseCase: useCase
            )
        )
        _overlayViewModel = StateObject(
            wrappedValue: FloatingEmojisOverlayViewModel(
                reactionsRepository: repository
            )
        )
    }

    var body: some View {
        ZStack {
            background

            FloatingEmojisOverlayView(viewModel: overlayViewModel)

            VStack {
                Spacer()
                bottomBar
            }
        }
    }

    // MARK: - Private Views

    private var background: some View {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            Text("Reactions Demo")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.top, 60)
        }
    }

    private var bottomBar: some View {
        EmojiButtonContainer(viewModel: buttonViewModel)
            .padding(.bottom, 32)
    }
}

// MARK: - Demo Implementations

/// Sends a reaction by writing it back to the shared repository,
/// creating a loopback so the floating overlay displays the emoji.
/// Cycles through different participant scenarios to demo all use cases.
private final class DemoSendReactionUseCase: SendReactionUseCase {
    private let repository: any ReactionsWriter
    private var callCount = 0

    /// Participant scenarios to cycle through.
    private let scenarios: [(name: String, isMe: Bool)] = [
        ("", true),  // Local user, empty name
        ("", false),  // Remote user, empty name
        ("Alice", false),  // Remote user with name
        ("Bob", false),  // Remote user with name
        ("Test", true),  // Local user with name
        ("Alexander Hamilton", false),  // Remote user long name
    ]

    init(repository: any ReactionsWriter) {
        self.repository = repository
    }

    func callAsFunction(_ emoji: String) throws {
        let scenario = scenarios[callCount % scenarios.count]
        callCount += 1

        let reaction = EmojiReaction(
            participantName: scenario.name,
            emoji: emoji,
            isMe: scenario.isMe
        )
        Task { await repository.addReaction(reaction) }
    }
}

#Preview {
    DemoReactionsView()
}
