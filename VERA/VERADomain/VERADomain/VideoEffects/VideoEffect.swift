//
//  Created by Vonage on 18/05/2026.
//

import Foundation

/// The video effect applied to the publisher's stream.
///
/// This is the single, unified type used to express all background effects:
/// no effect, blur at two intensities, or a virtual background image.
///
/// Only one effect is active at a time — applying a new one replaces the previous.
///
/// - SeeAlso: ``BlurLevel``
public enum VideoEffect: Equatable, Hashable, Codable {
    /// No effect — raw camera feed is published.
    case none

    /// Low-intensity background blur.
    case blurLow

    /// High-intensity background blur.
    case blurHigh

    /// Virtual background replacement with the image at the given file-system path.
    ///
    /// - Parameters:
    ///   - id: A stable identifier for the background (built-in IDs are fixed strings;
    ///         user-uploaded IDs use `"user_bg_<timestamp>"`).
    ///   - imagePath: The absolute file-system path that the SDK transformer reads directly.
    case backgroundImage(id: String, imagePath: String)

    /// Maps blur cases to the existing ``BlurLevel`` type used by ``BackgroundBlur`` params encoding.
    ///
    /// Returns `nil` for `.none` and `.backgroundImage`.
    public var blurLevel: BlurLevel? {
        switch self {
        case .blurLow: return .low
        case .blurHigh: return .high
        default: return nil
        }
    }
}
