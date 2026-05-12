//
//  Created by Vonage on 8/1/26.
//

import Foundation

public struct StopArchivingRequest {
    public let sessionKey: String
    public let archiveID: String

    public init(sessionKey: String, archiveID: String) {
        self.sessionKey = sessionKey
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
            sessionKey: request.sessionKey,
            archiveID: request.archiveID)
        _ = try await archivingDataSource.stopArchiving(newRequest)
    }
}
