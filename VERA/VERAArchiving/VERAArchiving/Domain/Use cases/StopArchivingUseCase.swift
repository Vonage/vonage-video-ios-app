//
//  Created by Vonage on 8/1/26.
//

import Foundation

public struct StopArchivingRequest {
    public let roomName: String
    public let archiveID: String

    public init(roomName: String, archiveID: String) {
        self.roomName = roomName
        self.archiveID = archiveID
    }
}

public protocol StopArchivingUseCase {
    func callAsFunction(_ request: StopArchivingRequest) async throws
}

public final class DefaultStopArchivingUseCase: StopArchivingUseCase {
    private let archivingDataSource: any ArchivingDataSource

    public init(archivingDataSource: any ArchivingDataSource) {
        self.archivingDataSource = archivingDataSource
    }

    public func callAsFunction(
        _ request: StopArchivingRequest
    ) async throws {
        let newRequest = StopArchivingDataSourceRequest(
            roomName: request.roomName,
            archiveID: request.archiveID)
        _ = try await archivingDataSource.stopArchiving(newRequest)
    }
}
