//
//  Created by Vonage on 11/11/25.
//

import Foundation
import VERACore

public func makeMockConnectToRoomUseCase() -> MockConnectToRoomUseCase {
    MockConnectToRoomUseCase()
}

public final class MockConnectToRoomUseCase: ConnectToRoomUseCase {
    public enum Actions: Equatable {
        case connect(String)
    }

    public var recordedActions: [Actions] = []

    public var call = MockCall()

    public func callAsFunction(
        roomName: VERACore.RoomName
    ) async throws -> any VERACore.CallFacade {
        recordedActions.append(.connect(roomName))
        return call
    }
}

public func makeFailingMockConnectToRoomUseCase() -> MockFailingConnectToRoomUseCase {
    MockFailingConnectToRoomUseCase()
}

public final class MockFailingConnectToRoomUseCase: ConnectToRoomUseCase {
    public enum Error: Swift.Error {
        case errorMock
    }

    public func callAsFunction(
        roomName: VERACore.RoomName
    ) async throws -> any VERACore.CallFacade {
        throw Error.errorMock
    }
}
