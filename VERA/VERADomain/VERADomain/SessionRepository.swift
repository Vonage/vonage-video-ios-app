//
//  Created by Vonage on 23/7/25.
//

import Foundation

public protocol SessionRepository {
    var currentCall: (any CallFacade)? { get }

    func createSession(for roomName: RoomName) async throws -> any CallFacade
    func clearSession()
}
