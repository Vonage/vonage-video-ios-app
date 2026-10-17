//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Integrator-facing configuration for On-the-Go mode.
public struct OnTheGoConfiguration: Equatable, Sendable {
    /// Master switch. When `false` the host should show nothing and the view
    /// model never starts motion detection.
    public let isEnabled: Bool

    /// When `false`, On-the-Go can only be entered manually: motion detection
    /// is never started and the motion permission is never requested.
    public let autoSuggest: Bool

    /// Seconds the suggestion banner stays visible before it counts as
    /// "Not now". Defaults to 10.
    public let suggestionTimeout: TimeInterval

    public init(
        isEnabled: Bool = true,
        autoSuggest: Bool = true,
        suggestionTimeout: TimeInterval = 10
    ) {
        self.isEnabled = isEnabled
        self.autoSuggest = autoSuggest
        self.suggestionTimeout = suggestionTimeout
    }
}
