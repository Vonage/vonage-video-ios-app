//
//  Created by Vonage on 8/1/26.
//

import Foundation

public struct StartArchivingRequest {
    public let roomName: String

    public init(roomName: String) {
        self.roomName = roomName
    }
}

public protocol StartArchivingUseCase {
    func callAsFunction(_ request: StartArchivingRequest) async throws -> ArchiveID
}

public final class DefaultStartArchivingUseCase: StartArchivingUseCase {
    private let archivingDataSource: any ArchivingDataSource

    public init(archivingDataSource: any ArchivingDataSource) {
        self.archivingDataSource = archivingDataSource
    }

    public func callAsFunction(
        _ request: StartArchivingRequest
    ) async throws -> ArchiveID {
        let request = StartArchivingDataSourceRequest(roomName: request.roomName)
        let response = try await archivingDataSource.startArchiving(request)
        return response.archiveId
    }
}
