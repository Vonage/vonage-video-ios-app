//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERACore

public protocol ArchivesDataSource {
    func getArchives(roomName: RoomName) async throws -> [Archive]
}
