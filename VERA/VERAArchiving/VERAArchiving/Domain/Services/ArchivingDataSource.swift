//
//  Created by Vonage on 8/1/26.
//

import Foundation

public enum ArchivingDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct StartArchivingDataSourceRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public struct StopArchivingDataSourceRequest {
    public let roomName: String
    public let archiveID: String

    public init(roomName: String, archiveID: String) {
        self.roomName = roomName
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
