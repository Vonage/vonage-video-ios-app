//
//  Created by Vonage on 8/1/26.
//

import Foundation
import VERADomain

public struct StartArchivingRequest: Sendable {
    public let sessionKey: String
    public let kind: ArchiveKind
    public let transcriptionOptions: TranscriptionOptions?

    public init(
        sessionKey: String,
        kind: ArchiveKind = .recording,
        transcriptionOptions: TranscriptionOptions? = nil
    ) {
        self.sessionKey = sessionKey
        self.kind = kind
        self.transcriptionOptions = transcriptionOptions
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
        let request = StartArchivingDataSourceRequest(
            sessionKey: request.sessionKey,
            kind: request.kind,
            transcriptionOptions: request.transcriptionOptions)
        let response = try await archivingDataSource.startArchiving(request)
        return response.archiveId
    }
}
