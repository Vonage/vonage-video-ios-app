//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERACore

public class MockArchivesDataSource: ArchivesDataSource {
    public init() {}
    
    public func getArchives(
        roomName: VERACore.RoomName
    ) async throws -> [VERACore.Archive] {
        return []
    }
}

public func makeMockArchivesDataSource() -> ArchivesDataSource {
    MockArchivesDataSource()
}
