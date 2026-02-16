//
//  Created by Vonage on 14/2/26.
//

import Combine
import Foundation

/// Constants for floating emoji overlay behavior.
private enum FloatingEmojisOverlayConstants {
    /// Buffer time after the animation completes before removing the view (seconds).
    static let removalBuffer: Double = 0.8

    /// Duration in seconds before a floating emoji is removed.
    ///
    /// Derived from the total balloon animation duration plus a buffer
    /// to ensure the view is fully invisible before removal.
    static let emojiLifetime: Double = BalloonAnimationConstants.totalDuration + removalBuffer

    /// Maximum number of emojis displayed simultaneously.
    static let maxVisibleEmojis: Int = 15
}

/// ViewModel that observes incoming reactions and manages floating emoji state.
///
/// Subscribes to `ReactionsRepository.reactionReceived` and maintains an array
/// of active `FloatingEmoji` items. Each emoji is automatically removed after
/// `emojiLifetime` seconds.
///
/// ## Usage
/// ```swift
/// let viewModel = FloatingEmojisOverlayViewModel(
///     reactionsRepository: repository
/// )
///
/// FloatingEmojisOverlayView(viewModel: viewModel)
/// ```
public final class FloatingEmojisOverlayViewModel: ObservableObject {

    // MARK: - Published Properties

    /// The currently visible floating emojis.
    @Published public private(set) var floatingEmojis: [UIFloatingEmoji] = []

    // MARK: - Private Properties

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Initialization

    /// Creates a floating emojis overlay ViewModel.
    /// - Parameter reactionsRepository: The repository to observe for incoming reactions.
    public init(reactionsRepository: any ReactionsObserver) {
        reactionsRepository.reactionReceived
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reaction in
                self?.addFloatingEmoji(reaction)
            }
            .store(in: &subscriptions)
    }

    // MARK: - Private Methods

    private func addFloatingEmoji(_ reaction: EmojiReaction) {
        let floatingEmoji = UIFloatingEmoji(reaction: reaction)

        floatingEmojis.append(floatingEmoji)

        // Enforce maximum visible emojis
        if floatingEmojis.count > FloatingEmojisOverlayConstants.maxVisibleEmojis {
            floatingEmojis.removeFirst()
        }

        // Schedule removal after lifetime expires
        scheduleRemoval(of: floatingEmoji.id)
    }

    private func scheduleRemoval(of emojiId: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + FloatingEmojisOverlayConstants.emojiLifetime) { [weak self] in
            self?.removeEmoji(emojiId)
        }
    }

    private func removeEmoji(_ emojiId: UUID) {
        floatingEmojis.removeAll { $0.id == emojiId }
    }
}
