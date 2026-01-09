//
//  Created by Vonage on 6/8/25.
//

import Foundation
import VERADomain

public final class PlayRecordingUseCase {

    private let archiveRecordingsRepository: ArchiveRecordingsRepository
    private let onPlay: (ArchiveRecording) -> Void

    public init(
        archiveRecordingsRepository: ArchiveRecordingsRepository,
        onPlay: @escaping (ArchiveRecording) -> Void
    ) {
        self.archiveRecordingsRepository = archiveRecordingsRepository
        self.onPlay = onPlay
    }

    @BackgroundActor
    public func callAsFunction(_ archive: Archive) async throws {
        let recording = try await archiveRecordingsRepository.getRecording(archive)

        await MainActor.run {
            onPlay(recording)
        }
    }
}
