//
//  Created by Vonage on 10/2/26.
//

import Combine
import Foundation

/// Writes reactions to the repository.
public protocol ReactionsWriter: Sendable {
    /// Adds a new reaction to the repository.
    /// - Parameter reaction: The reaction to add.
    func addReaction(_ reaction: EmojiReaction) async
}

/// Observes reactions from the repository.
public protocol ReactionsObserver: Sendable {
    /// Publisher that emits each new reaction as it arrives.
    var reactionReceived: AnyPublisher<EmojiReaction, Never> { get }
}

/// Repository for managing emoji reactions during a call.
///
/// Combines write and observe capabilities for reaction management.
/// Use `reactionReceived` to display floating emoji animations,
/// and `reactions` to access the full history if needed.
public typealias ReactionsRepository = ReactionsWriter & ReactionsObserver
