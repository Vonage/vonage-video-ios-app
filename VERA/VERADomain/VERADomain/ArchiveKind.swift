//
//  Created by Vonage on 11/10/26.
//

import Foundation

/// The kind of archive running in a session.
///
/// Recording and post-call transcription run as separate, concurrent archives.
/// The raw values match the archive names assigned by the backend.
public enum ArchiveKind: String, Equatable, Sendable, CaseIterable {
    /// A composed video recording of the session.
    case recording
    /// An audio-only archive used to generate a post-call transcription.
    case transcription

    /// Resolves the archive kind from the name reported by the Vonage session.
    ///
    /// Archives without a name, or with an unknown one, are treated as recordings
    /// so that backends predating transcription support keep working.
    ///
    /// - Parameter archiveName: The archive name reported when the archive started.
    public init(archiveName: String?) {
        self = archiveName.flatMap(ArchiveKind.init(rawValue:)) ?? .recording
    }
}
