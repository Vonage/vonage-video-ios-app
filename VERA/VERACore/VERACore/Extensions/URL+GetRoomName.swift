//
//  Created by Vonage on 13/8/25.
//

import Foundation

extension URL {
    /// Extracts the room name from a meeting URL
    /// - Parameter baseURL: The base domain URL
    /// - Returns: The room name or nil if not valid
    public func getRoomName(from baseURL: URL) -> String? {

        let selfHost = self.host?.lowercased()
        let baseHost = baseURL.host?.lowercased()

        // Hosts must match
        guard let selfHost = selfHost,
            let baseHost = baseHost,
            selfHost == baseHost
        else {
            return nil
        }

        // Get path components
        let pathComponents = self.pathComponents

        // Find room or waiting-room in path
        guard let roomIndex = pathComponents.firstIndex(where: { $0 == "room" || $0 == "waiting-room" }),
            roomIndex + 1 < pathComponents.count
        else {
            return nil
        }

        let roomName = pathComponents[roomIndex + 1]

        // Validate room name
        guard !roomName.isEmpty,
            roomName != "/",
            !roomName.hasPrefix("."),  // No hidden files
            !roomName.contains("/"),  // No additional slashes
            !roomName.contains("?"),  // No query params (shouldn't happen with pathComponents)
            !roomName.contains("#"),  // No fragments (shouldn't happen with pathComponents)
            roomName.allSatisfy({ $0.isASCII })  // ASCII only
        else {
            return nil
        }

        return roomName
    }
}
