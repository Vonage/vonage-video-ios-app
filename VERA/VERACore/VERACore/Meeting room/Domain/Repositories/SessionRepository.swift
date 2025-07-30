//
//  Created by Vonage on 23/7/25.
//

import Foundation

public protocol SessionRepository {
    var currentCall: (any CallFacade)? { get }

    func createSession(_ credentials: RoomCredentials) async -> any CallFacade
    func clearSession()
}
