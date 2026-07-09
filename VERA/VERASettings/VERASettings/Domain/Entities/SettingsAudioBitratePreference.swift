//
//  Created by Vonage on 11/06/2026.
//

import Foundation

/// User preference for the maximum audio bitrate.
public enum SettingsAudioBitratePreference: Codable, Equatable {
    /// Let the SDK choose the audio bitrate.
    case `default`

    /// Use an explicit maximum bitrate in bits per second.
    case custom(Int32)
}

extension SettingsAudioBitratePreference {
    var customValue: Int32? {
        switch self {
        case .default:
            nil
        case .custom(let value):
            value
        }
    }
}
