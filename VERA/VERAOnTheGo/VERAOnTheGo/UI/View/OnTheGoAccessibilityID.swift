//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Centralized accessibility identifiers for the On-the-Go feature.
///
/// Used by snapshot, UI and Maestro E2E tests to locate elements.
public enum OnTheGoAccessibilityID {
    /// The On-the-Go screen root.
    public static let screen = "onthego-screen"
    /// The Exit pill button.
    public static let exitButton = "onthego-exit-button"
    /// The big microphone toggle button.
    public static let muteButton = "onthego-mute-button"
    /// The active-speaker line.
    public static let activeSpeakerLabel = "onthego-active-speaker"
    /// The "View shared content" row.
    public static let sharedContentButton = "onthego-shared-content-button"
    /// The audio-route picker button.
    public static let audioRouteButton = "onthego-audio-route-button"
    /// The red Leave button.
    public static let leaveButton = "onthego-leave-button"
    /// The suggestion banner.
    public static let suggestionBanner = "onthego-suggestion-banner"
    /// The banner's Switch button.
    public static let suggestionSwitchButton = "onthego-suggestion-switch-button"
    /// The banner's Not now button.
    public static let suggestionNotNowButton = "onthego-suggestion-notnow-button"
    /// The shared-content sheet.
    public static let sharedContentSheet = "onthego-shared-content-sheet"
    /// The shared-content sheet's Done button.
    public static let sharedContentDoneButton = "onthego-shared-content-done"
    /// The settings screen's suggest-when-moving toggle.
    public static let suggestWhenMovingToggle = "onthego-suggest-when-moving-toggle"
    /// The settings screen's open-iOS-Settings button.
    public static let openSettingsButton = "onthego-open-settings-button"
    /// The meeting-room more-menu button that enters On-the-Go manually.
    public static let moreMenuButton = "on-the-go-button"
}
