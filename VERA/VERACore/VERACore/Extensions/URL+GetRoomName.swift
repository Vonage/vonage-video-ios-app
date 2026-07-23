//
//  Created by Vonage on 13/8/25.
//

import Foundation
import VERADomain

extension URL {
    /// Extracts the room identifier from a meeting URL
    /// - Parameter baseURL: The base domain URL
    /// - Returns: The room identifier or nil if not valid
    public func getRoomIdentifier(from baseURL: URL) -> RoomIdentifier? {

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

        let roomDescriptor = pathComponents[roomIndex + 1]

        if roomDescriptor.isJWT {
            return SessionKeyRoomIdentifier(sessionKey: roomDescriptor)
        }

        // Validate room name
        guard !roomDescriptor.isEmpty,
            roomDescriptor != "/",
            !roomDescriptor.hasPrefix("."),  // No hidden files
            !roomDescriptor.contains("/"),  // No additional slashes
            !roomDescriptor.contains("?"),  // No query params (shouldn't happen with pathComponents)
            !roomDescriptor.contains("#"),  // No fragments (shouldn't happen with pathComponents)
            roomDescriptor.allSatisfy({ $0.isASCII })  // ASCII only
        else {
            return nil
        }

        return PlainRoomIdentifier(roomName: roomDescriptor)
    }
}

extension String {
    var isJWT: Bool {
        let parts = split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return false }

        let base64URLCharacters = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        return parts.allSatisfy {
            !$0.isEmpty && CharacterSet(charactersIn: String($0)).isSubset(of: base64URLCharacters)
        }
    }
}
