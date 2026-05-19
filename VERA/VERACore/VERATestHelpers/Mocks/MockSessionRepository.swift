//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore
import VERADomain

public class MockSessionRepository: SessionRepository {
    public var currentCall: (any CallFacade)?
    public var createSessionError: (any Error)?
    public private(set) var createSessionCallCount = 0

    public func createSession(
        _ credentials: RoomCredentials
    ) async throws -> any CallFacade {
        createSessionCallCount += 1
        if let error = createSessionError {
            throw error
        }
        if let currentCall = currentCall {
            return currentCall
        }
        let call = MockCall()
        self.currentCall = call
        return call
    }

    public func clearSession() {
        self.currentCall = nil
    }
}

public func makeMockSessionRepository() -> MockSessionRepository {
    return .init()
}
