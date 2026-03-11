//
//  Created by Vonage on 01/03/2026.
//

/// Represents codec selection preferences for video publishing.
///
/// Derived from VERASettings' ``SettingsCodecPreference`` and converted to OpenTok's
/// `OTVideoCodecPreference` in VERAVonage. This domain-layer type keeps VERADomain
/// independent from both UI and SDK concerns.
///
/// The preference can be either automatic (SDK decides) or manual (user-ordered list).
///
/// - SeeAlso: ``VideoCodecType``, ``PublisherAdvancedSettings``
public struct VideoCodecPreference: Equatable {
    /// Whether codec selection should be automatic.
    /// - `true`: SDK automatically selects the best codec based on conditions
    /// - `false`: Use the manually ordered codec list in ``codecs``
    public let automatic: Bool

    /// The ordered list of preferred codecs (only meaningful when `automatic` is `false`).
    /// The SDK will try codecs in this order during negotiation.
    /// If `nil` or empty, automatic selection is used.
    public let codecs: [VideoCodecType]?

    /// Creates a new codec preference.
    ///
    /// - Parameters:
    ///   - automatic: Whether to use automatic codec selection.
    ///   - codecs: The ordered list of preferred codecs for manual mode.
    public init(automatic: Bool, codecs: [VideoCodecType]?) {
        self.automatic = automatic
        self.codecs = codecs
    }
}
