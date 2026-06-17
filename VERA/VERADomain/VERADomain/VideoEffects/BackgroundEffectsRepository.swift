//
//  Created by Vonage on 31/05/2026.
//

import Foundation

/// Provides access to built-in (stock) background images.
public protocol BackgroundEffectsRepository {
    /// Returns all available stock background items with resolved file paths.
    func availableBackgrounds() throws -> [VideoBackgroundItem]
}
