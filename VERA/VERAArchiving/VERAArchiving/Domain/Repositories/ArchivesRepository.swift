//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERADomain

public protocol ArchivesRepository {
    func getArchives(roomName: RoomName) async -> AnyPublisher<[Archive], Error>
}
