//
//  Created by Vonage on 11/06/2026.
//

import Foundation

/// Session metadata attached to feedback reports for diagnostics.
public struct FeedbackSessionDebugInfo: Equatable, Sendable {
    public let sessionId: String?
    public let connectionId: String?
    public let connectionCreationTime: Date?

    public init(
        sessionId: String? = nil,
        connectionId: String? = nil,
        connectionCreationTime: Date? = nil
    ) {
        self.sessionId = sessionId
        self.connectionId = connectionId
        self.connectionCreationTime = connectionCreationTime
    }

    public static let empty = FeedbackSessionDebugInfo()
}
