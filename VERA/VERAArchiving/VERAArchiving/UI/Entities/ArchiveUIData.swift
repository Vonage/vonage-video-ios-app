//
//  Created by Vonage on 4/8/25.
//

import Foundation

public struct ArchiveUIData: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let isDownloadable: Bool

    public var onDownload: (@Sendable () -> Void)?

    public init(
        id: UUID,
        title: String,
        subtitle: String,
        isDownloadable: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isDownloadable = isDownloadable
    }
}
