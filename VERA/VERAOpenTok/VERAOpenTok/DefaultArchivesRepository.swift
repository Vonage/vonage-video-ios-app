//
//  Created by Vonage on 4/8/25.
//

import Combine
import Foundation
import VERACore

public final class DefaultArchivesRepository: ArchivesRepository {

    public init() {}

    public func getArchives(roomName: VERACore.RoomName) -> AnyPublisher<[VERACore.Archive], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
