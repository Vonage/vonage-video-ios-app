//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore

public class MockSessionRepository: SessionRepository {
    public var currentCall: (any VERACore.CallFacade)?

    public func createSession(
        _ credentials: VERACore.RoomCredentials
    ) async -> any VERACore.CallFacade {
        let call = MockCall()
        self.currentCall = call
        return call
    }

    public func clearSession() {
        self.currentCall = nil
    }
}
