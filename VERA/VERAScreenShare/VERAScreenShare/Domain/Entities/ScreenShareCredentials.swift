//
//  Created by Vonage on 26/2/26.
//

import Foundation

/// Credentials required by the broadcast extension to join the Vonage session.
///
/// These values are written by the main app into a shared App Group and read
/// by the Broadcast Upload Extension to connect and publish the screen share stream.
public struct ScreenShareCredentials: Equatable {
    /// The Vonage application (API) key.
    public let applicationId: String
    /// The Vonage session identifier.
    public let sessionId: String
    /// The Vonage token used to authenticate and connect.
    public let token: String

    public init(applicationId: String, sessionId: String, token: String) {
        self.applicationId = applicationId
        self.sessionId = sessionId
        self.token = token
    }
}
