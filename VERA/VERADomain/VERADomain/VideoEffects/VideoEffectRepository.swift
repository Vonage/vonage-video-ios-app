//
//  Created by Vonage on 31/05/2026.
//

import Foundation

/// Persists the user's selected video effect across sessions.
public protocol VideoEffectRepository {
    /// Saves the current video effect selection.
    func save(_ effect: VideoEffect) throws

    /// Loads the previously saved video effect, or `.none` if nothing was saved
    /// or if the saved effect references a deleted background image.
    func load() -> VideoEffect
}
