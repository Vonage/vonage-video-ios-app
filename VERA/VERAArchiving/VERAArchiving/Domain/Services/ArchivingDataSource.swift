//
//  Created by Vonage on 8/1/26.
//

import Foundation
import VERADomain

public enum ArchivingDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct StartArchivingDataSourceRequest: Sendable {
    public let sessionKey: String
    public let kind: ArchiveKind

    public init(sessionKey: String, kind: ArchiveKind = .recording) {
        self.sessionKey = sessionKey
        self.kind = kind
    }
}

public struct StopArchivingDataSourceRequest: Sendable {
    public let sessionKey: String
    public let archiveID: String
    public let kind: ArchiveKind

    public init(sessionKey: String, archiveID: String, kind: ArchiveKind = .recording) {
        self.sessionKey = sessionKey
        self.archiveID = archiveID
        self.kind = kind
    }
}

public typealias ArchiveID = String

public struct StartArchivingDataSourceResponse: Sendable {
    public let archiveId: ArchiveID

    public init(archiveId: ArchiveID) {
        self.archiveId = archiveId
    }
}

public struct StopArchivingDataSourceResponse: Sendable {
    public let archiveId: ArchiveID

    public init(archiveId: ArchiveID) {
        self.archiveId = archiveId
    }
}

public protocol ArchivingDataSource: Sendable {
    func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse

    func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse
}
