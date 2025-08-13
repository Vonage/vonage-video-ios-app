//
//  Created by Vonage on 13/8/25.
//

import Foundation

extension URL {
    /// Extracts the room name from a meeting URL
    /// - Parameter baseURL: The base domain URL
    /// - Returns: The room name or nil if not valid
    public func getRoomName(from baseURL: URL) -> String? {
        // Compare hosts (domains)
        guard self.host == baseURL.host else {
            return nil
        }

        // Extract the path without the initial "/"
        let roomName = String(self.path.dropFirst())

        // Validate that it's not empty and doesn't contain invalid characters
        guard !roomName.isEmpty,
            !roomName.contains("/"),  // No sub-paths
            !roomName.hasPrefix(".")
        else {  // No hidden files
            return nil
        }

        return roomName
    }
}
