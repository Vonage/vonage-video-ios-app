//
//  Created by Vonage on 27/9/26.
//

import Foundation

public protocol SessionProvider {
    associatedtype Session
    func makeSession(for roomName: RoomName) async throws -> Session
}
