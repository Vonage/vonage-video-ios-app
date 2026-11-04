//
//  Created by Vonage on 4/8/25.
//

import Foundation
import VERADomain

public struct ArchiveUIData: Identifiable, Sendable {

    /// Whether the row's file can be downloaded yet.
    public enum DownloadState: Equatable, Sendable {
        /// The file is still being produced.
        case preparing
        /// The file can be downloaded.
        case ready
        /// The file failed, expired, or has no download URL.
        case unavailable
    }

    public let id: UUID
    public let kind: ArchiveKind
    public let title: String
    public let subtitle: String
    public let downloadState: DownloadState

    public var onDownload: (@Sendable () -> Void)?

    public init(
        id: UUID,
        kind: ArchiveKind = .recording,
        title: String,
        subtitle: String,
        downloadState: DownloadState
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.downloadState = downloadState
    }
}
