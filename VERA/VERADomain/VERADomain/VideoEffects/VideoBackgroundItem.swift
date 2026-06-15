//
//  Created by Vonage on 31/05/2026.
//

import Foundation

/// A background image available for virtual background replacement.
///
/// Represents either a built-in stock image or a user-uploaded photo.
public struct VideoBackgroundItem: Identifiable, Equatable, Hashable {
    /// Unique identifier for this background.
    public let id: String

    /// Asset catalog name for built-in thumbnails, `nil` for user-uploaded images.
    public let thumbnailResource: String?

    /// Absolute file-system path to the full-size image used by the SDK transformer.
    public let imagePath: String

    /// Whether this background was uploaded by the user.
    public let isUserUploaded: Bool

    public init(
        id: String,
        thumbnailResource: String? = nil,
        imagePath: String,
        isUserUploaded: Bool
    ) {
        self.id = id
        self.thumbnailResource = thumbnailResource
        self.imagePath = imagePath
        self.isUserUploaded = isUserUploaded
    }
}
