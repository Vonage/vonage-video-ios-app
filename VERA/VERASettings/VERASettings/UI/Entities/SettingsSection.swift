//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Sections available in the settings dashboard sidebar.
///
/// Each case represents one navigation item. The order of ``allCases``
/// determines the display order in both compact and sidebar layouts.
public enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general = "General"
    case video = "Video"
    case screenSharing = "Screen Sharing"
    case audio = "Audio"
    case stats = "Stats"

    /// Unique identifier used by `ForEach` and `NavigationSplitView`.
    ///
    /// Returns `self` so the `ID` associated type is `SettingsSection`,
    /// matching the `List(selection:)` binding type in ``SettingsView``.
    public var id: Self { self }
}

// MARK: - Display

extension SettingsSection {
    /// SF Symbol name for the section icon.
    public var iconName: String {
        return switch self {
        case .general: "gear"
        case .video: "video"
        case .screenSharing: "rectangle.on.rectangle"
        case .audio: "waveform"
        case .stats: "chart.bar"
        }
    }

    /// Human-readable label for the section.
    public var displayName: String {
        self == .stats ? "Statistics".localized : rawValue.localized
    }
}
