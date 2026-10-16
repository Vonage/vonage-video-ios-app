//
//  Created by Vonage on 7/6/26.
//

import Foundation
import VERAArchiving
import VERADomain

public final class E2EArchivingDataSource: ArchivingDataSource {
    private let decorated: any ArchivingDataSource
    private let archivingStatusDataSource: any ArchivingStatusDataSource
    private let transcriptionStatusDataSource: any ArchivingStatusDataSource

    public init(
        decorated: any ArchivingDataSource,
        archivingStatusDataSource: any ArchivingStatusDataSource,
        transcriptionStatusDataSource: any ArchivingStatusDataSource
    ) {
        self.decorated = decorated
        self.archivingStatusDataSource = archivingStatusDataSource
        self.transcriptionStatusDataSource = transcriptionStatusDataSource
    }

    public func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        let response = try await decorated.startArchiving(request)
        statusDataSource(for: request.kind).set(archivingState: .archiving(response.archiveId))
        NotificationCenter.default.post(
            name: E2EArchivingEvents.didStart,
            object: response.archiveId,
            userInfo: [E2EArchivingEvents.kindKey: request.kind])
        return response
    }

    public func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        let response = try await decorated.stopArchiving(request)
        statusDataSource(for: request.kind).set(archivingState: .idle)
        NotificationCenter.default.post(
            name: E2EArchivingEvents.didStop,
            object: nil,
            userInfo: [E2EArchivingEvents.kindKey: request.kind])
        return response
    }

    private func statusDataSource(for kind: ArchiveKind) -> any ArchivingStatusDataSource {
        switch kind {
        case .recording: archivingStatusDataSource
        case .transcription: transcriptionStatusDataSource
        }
    }
}
