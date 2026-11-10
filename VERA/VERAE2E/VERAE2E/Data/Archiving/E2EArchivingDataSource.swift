//
//  Created by Vonage on 7/6/26.
//

import Foundation
import VERAArchiving
import VERADomain

public final class E2EArchivingDataSource: ArchivingDataSource {
    private let decorated: any ArchivingDataSource
    private let archivingStatusDataSource: any ArchivingStatusDataSource

    public init(
        decorated: any ArchivingDataSource,
        archivingStatusDataSource: any ArchivingStatusDataSource
    ) {
        self.decorated = decorated
        self.archivingStatusDataSource = archivingStatusDataSource
    }

    public func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        let response = try await decorated.startArchiving(request)
        archivingStatusDataSource.set(archivingState: .archiving(response.archiveId), for: request.kind)
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
        archivingStatusDataSource.set(archivingState: .idle, for: request.kind)
        NotificationCenter.default.post(
            name: E2EArchivingEvents.didStop,
            object: nil,
            userInfo: [E2EArchivingEvents.kindKey: request.kind])
        return response
    }

}
