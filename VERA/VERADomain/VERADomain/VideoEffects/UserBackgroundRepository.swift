//
//  Created by Vonage on 31/05/2026.
//

import Foundation

/// Manages user-uploaded background images.
public protocol UserBackgroundRepository {
    /// Maximum number of user-uploaded backgrounds allowed.
    static var maxUserBackgrounds: Int { get }

    /// Returns all saved user-uploaded background items.
    func savedBackgrounds() throws -> [VideoBackgroundItem]

    /// Saves image data as a new user background.
    ///
    /// The image is center-cropped to portrait aspect ratio and saved as JPEG.
    /// - Parameter imageData: Raw image data (PNG or JPEG).
    /// - Returns: The newly created background item.
    func save(_ imageData: Data) throws -> VideoBackgroundItem

    /// Deletes a user-uploaded background by its identifier.
    func delete(_ id: String) throws

    /// The number of remaining upload slots.
    var remainingSlots: Int { get }
}
