//
//  Created by Vonage on 8/1/26.
//

import Foundation
import VERAArchiving

public final class MockArchivingDataSource: ArchivingDataSource {

    var error: Error?
    var lastRoomName: String?
    var lastArchiveID: String?

    public func startArchiving(_ request: StartArchivingDataSourceRequest) async throws {
        if let error = error {
            throw error
        }
        lastRoomName = request.roomName
    }

    public func stopArchiving(_ request: StopArchivingDataSourceRequest) async throws {
        if let error = error {
            throw error
        }
        lastRoomName = request.roomName
        lastArchiveID = request.archiveID
    }
}
