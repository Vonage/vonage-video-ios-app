//
//  Created by Vonage on 10/6/26.
//

import Foundation

/// How the user wants the audio bitrate to be selected.
public enum SettingsAudioBitrateMode: String, Equatable, CaseIterable, Identifiable {
    /// Let the SDK choose the audio bitrate automatically.
    case `default`

    /// The user specifies an explicit maximum audio bitrate.
    case custom

    public var id: String { rawValue }
}

// MARK: - Display

extension SettingsAudioBitrateMode {
    /// Human-readable label shown in the Settings UI.
    public var displayName: String {
        return switch self {
        case .default: "Default".localized
        case .custom: "Custom".localized
        }
    }
}
