//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation

public protocol ArchivesRepository {
    func getArchives(roomName: RoomName) -> AnyPublisher<[Archive], Never>
}
