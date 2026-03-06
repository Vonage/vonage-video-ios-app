//
//  Created by Vonage on 21/02/26.
//

import Foundation

/// The preferred video codec for the publisher.
///
/// Maps to ``VideoCodecType`` in VERADomain and `OTPublisherKitVideoCodec` in the Vonage Video SDK.
/// Each codec has different characteristics in terms of compression efficiency, browser compatibility,
/// and quality.
///
/// Conforms to `Codable` for `UserDefaults` persistence (encoded as its raw `Int` value)
/// and `Equatable` for comparison in tests and SwiftUI diffing. The raw value matches
/// both ``VideoCodecType`` and the Vonage SDK's `OTPublisherKitVideoCodec` enum values
/// for seamless bridging across all layers.
///
/// ## Codec Characteristics
///
/// - **VP8** (raw value: 1): Google's open video codec, widely supported across browsers
///   and platforms. Good balance between quality and compatibility.
///
/// - **H.264** (raw value: 2): Industry-standard codec with excellent hardware acceleration
///   support. Best compatibility with native iOS/macOS devices. Requires licensing in some contexts.
///
/// - **VP9** (raw value: 3): Google's next-generation codec offering better compression than VP8.
///   Provides higher quality at lower bitrates but may have limited hardware acceleration.
///
/// ## Domain Mapping
///
/// This Settings module type is converted to VERADomain's ``VideoCodecType`` via the
/// ``vonageCodec`` computed property defined in `PublisherSettingsPreferences+Bridge`.
/// Since both enums share identical raw values, the conversion is direct and type-safe:
///
/// ```swift
/// let settingsCodec: SettingsVideoCodec = .vp9
/// let domainCodec: VideoCodecType = settingsCodec.vonageCodec // .vp9
/// ```
///
/// This bridging pattern ensures VERADomain remains independent from VERASettings.
///
/// ## Usage
///
/// Users can select a codec preference through the Settings UI. In automatic mode,
/// the SDK negotiates the best codec based on network conditions and participant capabilities.
/// In manual mode, users can order these codecs by priority via ``SettingsCodecPreference/orderedCodecs``.
///
/// ## Persistence
///
/// When saved to `UserDefaults` as part of ``PublisherSettingsPreferences``, the codec
/// is stored as its integer raw value (1, 2, or 3). This ensures backward compatibility
/// and efficient storage.
///
/// - SeeAlso: ``SettingsCodecPreference``, ``SettingsCodecMode``, ``VideoCodecType``
public enum SettingsVideoCodec: Int, CaseIterable, Codable, Equatable, Identifiable {
    /// VP8 codec - Google's widely-supported open video codec.
    case vp8 = 1

    /// H.264 codec - Industry-standard with excellent hardware support.
    case h264 = 2

    /// VP9 codec - Google's next-generation codec with improved compression.
    case vp9 = 3

    /// Unique identifier for the codec, using the raw value.
    ///
    /// Conforms to `Identifiable` for use in SwiftUI lists and ForEach loops.
    public var id: Int { rawValue }
}

// MARK: - Display

extension SettingsVideoCodec {
    /// Human-readable label shown in the Settings UI.
    ///
    /// Provides the standard codec name as displayed to users in settings screens
    /// and debug interfaces.
    ///
    /// - Returns: The codec name string (e.g., "VP8", "H.264", "VP9").
    public var displayName: String {
        return switch self {
        case .vp8: "VP8"
        case .h264: "H.264"
        case .vp9: "VP9"
        }
    }
}
