//
//  Created by Vonage on 22/2/26.
//

import Foundation

/// Sections available in the settings dashboard sidebar.
///
/// Each case represents one navigation item. The order of ``allCases``
/// determines the display order in the sidebar list.
public enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case general = "General"
    case video = "Video"
    case audio = "Audio"
    case stats = "Stats"

    /// Unique identifier used by `ForEach` and `NavigationSplitView`.
    ///
    /// Returns `self` so the `ID` associated type is `SettingsSection`,
    /// matching the `List(selection:)` binding type in ``SettingsView``.
    public var id: Self { self }
}

// MARK: - Display

public extension SettingsSection {
    /// SF Symbol name for the section icon.
     var iconName: String {
        return switch self {
        case .general: "gear"
        case .video: "video"
        case .audio: "waveform"
        case .stats: "chart.bar"
        }
    }

    /// Human-readable label for the section.
     var displayName: String { rawValue.localized }
}
