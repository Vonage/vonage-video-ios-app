//
//  Created by Vonage on 6/8/25.
//

import Foundation
import VERADomain

public final class PlayRecordingUseCase {

    public enum Error: Swift.Error {
        case missingURL
    }

    private let onPlay: (ArchiveRecording) -> Void

    public init(onPlay: @escaping (ArchiveRecording) -> Void) {
        self.onPlay = onPlay
    }

    public func callAsFunction(_ archive: Archive) async throws {
        guard let url = archive.url else {
            throw Error.missingURL
        }
        onPlay(ArchiveRecording(url: url))
    }
}
