//
//  Created by Vonage on 6/8/25.
//

import Foundation
import VERADomain

@MainActor
public protocol PlayRecordingUseCase {
    func callAsFunction(_ archive: Archive) async throws
}

public final class DefaultPlayRecordingUseCase: PlayRecordingUseCase {

    public enum Error: Swift.Error {
        case missingURL
    }

    private let onPlay: (ArchiveRecording) -> Void

    public init(onPlay: @escaping (ArchiveRecording) -> Void) {
        self.onPlay = onPlay
    }

    /// Opens the archive's file: the recording, or the transcript zip for transcriptions.
    public func callAsFunction(_ archive: Archive) async throws {
        guard let url = archive.downloadURL else {
            throw Error.missingURL
        }
        onPlay(ArchiveRecording(url: url))
    }
}
