//
//  Created by Vonage on 10/7/25.
//

import Foundation
import VERACore
import VERADomain

public func makeBasicRoomNameGenerator() -> RoomNameGenerator {
    RoomNameGenerator(
        categories: [.init(words: ["aardvark"])]
    )
}
