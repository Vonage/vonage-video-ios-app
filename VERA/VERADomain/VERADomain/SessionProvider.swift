//
//  Created by Vonage on 27/9/26.
//

import Foundation

@MainActor
public protocol SessionProvider: Sendable {
    associatedtype Session
    func makeSession(for roomName: RoomName) async throws -> Session
}
