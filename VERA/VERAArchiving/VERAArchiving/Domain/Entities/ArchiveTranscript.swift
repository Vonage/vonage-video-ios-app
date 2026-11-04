//
//  Created by Vonage on 18/10/26.
//

import Foundation

/// A post-call transcript downloaded to a local file, ready to be shared or saved.
public struct ArchiveTranscript: Identifiable, Equatable, Sendable {
    /// Identifier of the transcription archive the transcript belongs to.
    public let id: UUID
    /// Local URL of the downloaded transcript zip.
    public let fileURL: URL

    public init(id: UUID, fileURL: URL) {
        self.id = id
        self.fileURL = fileURL
    }
}
