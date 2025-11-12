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

public func makeFailingMockDisconnectRoomUseCase() -> MockFailingDisconnectRoomUseCase {
    MockFailingDisconnectRoomUseCase()
}

public final class MockFailingDisconnectRoomUseCase: DisconnectRoomUseCase {
    public enum Error: Swift.Error {
        case errorMock
    }

    public func callAsFunction() async throws {
        throw Error.errorMock
    }
}
