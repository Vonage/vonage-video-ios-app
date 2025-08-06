//
//  Created by Vonage on 6/8/25.
//

import Foundation

public protocol ArchiveRecordingsRepository {
    func getRecording(_ archive: Archive) async throws -> ArchiveRecording
}
