//
//  Created by Vonage on 23/7/25.
//

import Foundation

public protocol SessionRepository {
    func createSession(_ credentials: RoomCredentials)
}
