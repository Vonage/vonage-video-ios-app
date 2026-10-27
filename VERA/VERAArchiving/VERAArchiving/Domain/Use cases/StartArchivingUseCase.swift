//
//  Created by Vonage on 8/1/26.
//

import Foundation
import VERADomain

public struct StartArchivingRequest: Sendable {
    public let sessionKey: String
    public let kind: ArchiveKind

    public init(sessionKey: String, kind: ArchiveKind = .recording) {
        self.sessionKey = sessionKey
        self.kind = kind
    }
}

public protocol StartArchivingUseCase: Sendable {
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
        let request = StartArchivingDataSourceRequest(sessionKey: request.sessionKey, kind: request.kind)
        let response = try await archivingDataSource.startArchiving(request)
        return response.archiveId
    }
}
