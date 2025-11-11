//
//  Created by Vonage on 11/11/25.
//

import Foundation
import VERACore

public func makeMockDisconnectRoomUseCase() -> MockDisconnectRoomUseCase {
    MockDisconnectRoomUseCase()
}

public final class MockDisconnectRoomUseCase: DisconnectRoomUseCase {

    public enum Actions {
        case disconnect
    }

    public var recordedActions: [Actions] = []

    public func callAsFunction() async throws {
        recordedActions.append(.disconnect)
    }
}
