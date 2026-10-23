//
//  Created by Vonage on 23/7/25.
//

import Foundation

@MainActor
public protocol SessionRepository: Sendable {
    var currentCall: (any CallFacade)? { get }

    func createSession(for roomName: RoomName) async throws -> any CallFacade
    func clearSession()
}
