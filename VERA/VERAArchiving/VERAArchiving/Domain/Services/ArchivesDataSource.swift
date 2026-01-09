//
//  Created by Vonage on 5/8/25.
//

import Foundation
import VERADomain

public protocol ArchivesDataSource {
    func getArchives(roomName: RoomName) async throws -> [Archive]
}
