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

public protocol ArchivingDataSource {
    func startArchiving(_ request: StartArchivingDataSourceRequest) async throws
    func stopArchiving(_ request: StopArchivingDataSourceRequest) async throws
}
