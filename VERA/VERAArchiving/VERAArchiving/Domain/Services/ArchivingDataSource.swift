//
//  Created by Vonage on 8/1/26.
//

import Foundation

public enum ArchivingDataSourceError: Swift.Error {
    case networkError
    case invalidData
}

public struct ArchivingDataSourceRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public protocol ArchivingDataSource {
    func startArchiving(_ request: ArchivingDataSourceRequest) async throws
    func stopArchiving(_ request: ArchivingDataSourceRequest) async throws
}
