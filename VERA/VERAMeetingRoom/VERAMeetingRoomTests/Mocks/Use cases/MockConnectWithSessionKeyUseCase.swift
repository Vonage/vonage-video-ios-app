//
//  Created by Vonage on 23/7/25.
//

import Foundation
import VERAMeetingRoom
import VERATestHelpers

public func makeMockConnectWithSessionKeyUseCase() -> MockConnectWithSessionKeyUseCase {
    MockConnectWithSessionKeyUseCase()
}

public final class MockConnectWithSessionKeyUseCase: ConnectWithSessionKeyUseCase {
    public enum Actions: Equatable {
        case connectWithSessionKey(String)
    }

    public var recordedActions: [Actions] = []

    public var call = MockCall()

    public func callAsFunction(
        sessionKey: String
    ) async throws -> any CallFacade {
        recordedActions.append(.connectWithSessionKey(sessionKey))
        return call
    }
}

public func makeFailingMockConnectWithSessionKeyUseCase() -> MockFailingConnectWithSessionKeyUseCase {
    MockFailingConnectWithSessionKeyUseCase()
}

public final class MockFailingConnectWithSessionKeyUseCase: ConnectWithSessionKeyUseCase {
    public enum Error: Swift.Error {
        case errorMock
    }

    public func callAsFunction(
        sessionKey: String
    ) async throws -> any CallFacade {
        throw Error.errorMock
    }
}
