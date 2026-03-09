//
//  Created by Vonage on 14/2/26.
//

import Combine
import SwiftUI

/// An overlay view that displays floating animated emojis from incoming reactions.
///
/// Place this view as an overlay on top of the video feed. It observes
/// `FloatingEmojisOverlayViewModel` for new reactions and renders each one
/// as a `FloatingEmojiView` at a random horizontal position.
///
/// ## Usage
/// ```swift
/// ZStack {
///     VideoFeedView()
///     FloatingEmojisOverlayView(viewModel: viewModel)
/// }
/// ```
///
/// - SeeAlso: ``FloatingEmojisOverlayViewModel``, ``FloatingEmojiView``
public struct FloatingEmojisOverlayView: View {

    // MARK: - Properties

    /// The ViewModel providing the active floating emojis.
    @ObservedObject private var viewModel: FloatingEmojisOverlayViewModel


    // MARK: - Initialization

    /// Creates a floating emojis overlay view.
    /// - Parameter viewModel: The ViewModel managing floating emoji state.
    public init(viewModel: FloatingEmojisOverlayViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.floatingEmojis) { floatingEmoji in
                    FloatingEmojiView(
                        emoji: floatingEmoji.emoji, participantName: floatingEmoji.participantName,
                        isMe: floatingEmoji.isMe
                    )
                    .balloonAnimation(containerHeight: geometry.size.height)
                    .position(
                        x: floatingEmoji.horizontalPosition * geometry.size.width,
                        y: geometry.size.height * 0.85
                    )
                    .transition(.identity)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Private

    private var accessibilityDescription: String {
        guard !viewModel.floatingEmojis.isEmpty else { return "" }
        let count = viewModel.floatingEmojis.count
        return "\(count) reaction\(count == 1 ? "" : "s") on screen"
    }
}

// MARK: - Preview

#if DEBUG
    private struct FloatingEmojisOverlayPreview: View {
        @State private var observer = PreviewReactionsObserver()

        var body: some View {
            ZStack {
                Color.black.opacity(0.3).ignoresSafeArea()

                FloatingEmojisOverlayView(
                    viewModel: FloatingEmojisOverlayViewModel(
                        reactionsRepository: observer
                    )
                )
            }
        }
    }

    #Preview {
        FloatingEmojisOverlayPreview()
    }

    private final class PreviewReactionsObserver: ReactionsObserver, @unchecked Sendable {
        private let subject = PassthroughSubject<EmojiReaction, Never>()

        var reactionReceived: AnyPublisher<EmojiReaction, Never> {
            subject.eraseToAnyPublisher()
        }

        init() {
            let emojis = ["🎉", "👍", "❤️", "😂", "🔥"]
            var index = 0
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
                let reaction = EmojiReaction(
                    participantName: "Preview User",
                    emoji: emojis[index % emojis.count],
                    isMe: Bool.random()
                )
                self?.subject.send(reaction)
                index += 1
            }
        }
    }
#endif
