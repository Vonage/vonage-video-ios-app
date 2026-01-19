//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore
import VERADomain

public class MockSessionRepository: SessionRepository {
    public var currentCall: (any CallFacade)?

    public func createSession(
        _ credentials: RoomCredentials
    ) async -> any CallFacade {
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
