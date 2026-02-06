//
//  Created by Vonage on 6/2/26.
//

import Foundation

public enum CaptionsDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct EnableCaptionsDataSourceRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public struct DisableCaptionsDataSourceRequest {
    public let roomName: String
    public let captionsID: String

    public init(roomName: String, captionsID: String) {
        self.roomName = roomName
        self.captionsID = captionsID
    }
}

public typealias ArchiveID = String

public struct EnableCaptionsDataSourceResponse {
    public let archiveId: ArchiveID

    public init(archiveId: ArchiveID) {
        self.archiveId = archiveId
    }
}

public protocol CaptionsDataSource {
    func enableCaptions(
        _ request: EnableCaptionsDataSourceRequest
    ) async throws -> EnableCaptionsDataSourceResponse

    func disableCaptions(
        _ request: DisableCaptionsDataSourceRequest
    ) async throws
}
