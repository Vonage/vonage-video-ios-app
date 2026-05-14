//
//  Created by Vonage on 8/1/26.
//

import Foundation

public enum ArchivingDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct StartArchivingDataSourceRequest {
    public let sessionKey: String

    public init(sessionKey: String) {
        self.sessionKey = sessionKey
    }
}

public struct StopArchivingDataSourceRequest {
    public let sessionKey: String
    public let archiveID: String

    public init(sessionKey: String, archiveID: String) {
        self.sessionKey = sessionKey
        self.archiveID = archiveID
    }
}

public typealias ArchiveID = String

public struct StartArchivingDataSourceResponse {
    public let archiveId: ArchiveID

    public init(archiveId: ArchiveID) {
        self.archiveId = archiveId
    }
}

public struct StopArchivingDataSourceResponse {
    public let archiveId: ArchiveID

    public init(archiveId: ArchiveID) {
        self.archiveId = archiveId
    }
}

public protocol ArchivingDataSource {
    func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse

    func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse
}
