//
//  Created by Vonage on 04/03/2026.
//

/// Defines how video should be scaled when displayed in a view.
///
/// This enum controls the aspect ratio and scaling behavior of video content
/// when the video dimensions don't match the view dimensions.
///
/// - SeeAlso: ``PublisherSettings``
public enum VideoScaleBehavior: String, Equatable {
    /// Fill the entire view, potentially cropping video to maintain aspect ratio.
    /// The video will be scaled to fill the view completely, which may result in
    /// some portions being cropped if the aspect ratios don't match.
    case fill

    /// Fit the video within the view, maintaining aspect ratio with letterboxing/pillarboxing.
    /// The entire video will be visible with black bars added as needed to preserve
    /// the original aspect ratio.
    case fit
}
