//
//  Created by Vonage on 10/2/26.
//

import Combine
import SwiftUI
import VERAReactions

@main
struct VERAReactionsApp: App {
    var body: some Scene {
        WindowGroup {
            DemoEmojiPickerView()
        }
    }
}

struct DemoEmojiPickerView: View {
    @State private var selectedEmoji: UIEmojiReaction?
    @State private var lastSentEmoji: String?
    @StateObject private var viewModel: EmojiPickerContainerViewModel

    init() {
        let useCase = DemoSendReactionUseCase()
        _viewModel = StateObject(
            wrappedValue: EmojiPickerContainerViewModel(
                sendReactionUseCase: useCase
            ))
    }

    var body: some View {
        ZStack {
            // Simulated video background
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // EmojiPickerView overlay
            emojiPickerContainerView

            // Demo controls
            VStack {
                Text("EmojiPickerView Demo")
                    .font(.title)
                    .foregroundStyle(.white)
                    .padding()

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var emojiPickerContainerView: some View {
        VStack(spacing: 32) {
            Text(selectedEmoji?.emoji ?? "👆")
                .font(.system(size: 64))

            Text(selectedEmoji?.name ?? "Tap an emoji")
                .font(.headline)

            // Use EmojiPickerViewContainer with the ViewModel
            EmojiPickerViewContainer(viewModel: viewModel)
        }
        .padding()
    }
}

// MARK: - Demo Implementations

/// Demo implementation of SendReactionUseCase for preview purposes.
private final class DemoSendReactionUseCase: SendReactionUseCase {
    func callAsFunction(_ emoji: String) throws {
        print("Demo: Sending reaction \(emoji)")
    }
}

/// Demo implementation of ReactionsRepository for factory usage.
private final class DemoReactionsRepository: ReactionsRepository {
    private let subject = PassthroughSubject<EmojiReaction, Never>()
    private(set) var reactions: [EmojiReaction] = []

    var reactionReceived: AnyPublisher<EmojiReaction, Never> {
        subject.eraseToAnyPublisher()
    }

    func addReaction(_ reaction: EmojiReaction) {
        reactions.append(reaction)
        subject.send(reaction)
    }

    func clear() {
        reactions.removeAll()
    }
}

#Preview {
    DemoEmojiPickerView()
}
