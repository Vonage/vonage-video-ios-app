//
//  Created by Vonage on 8/1/26.
//

import Foundation
import VERAArchiving

public final class MockArchivingDataSource: ArchivingDataSource {
    var error: Error?
    var lastRoomName: String?
    var lastArchiveID: String?

    var startResponse: VERAArchiving.StartArchivingDataSourceResponse?
    var stopResponse: VERAArchiving.StopArchivingDataSourceResponse?

    public func startArchiving(
        _ request: VERAArchiving.StartArchivingDataSourceRequest
    ) async throws -> VERAArchiving.StartArchivingDataSourceResponse {
        if let error = error {
            throw error
        }
        lastRoomName = request.roomName

        return startResponse ?? .init(archiveId: "123")
    }

    public func stopArchiving(
        _ request: VERAArchiving.StopArchivingDataSourceRequest
    ) async throws -> VERAArchiving.StopArchivingDataSourceResponse {
        if let error = error {
            throw error
        }
        lastRoomName = request.roomName
        lastArchiveID = request.archiveID

        return stopResponse ?? .init(archiveId: "123")
    }


}
