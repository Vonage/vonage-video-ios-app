//
//  Created by Vonage on 4/8/25.
//

import Foundation

public enum ArchiveStatus {
    case stopped, available
}

public struct Archive {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let status: ArchiveStatus
    public let url: URL?

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        status: ArchiveStatus,
        url: URL?
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.status = status
        self.url = url
    }
}
