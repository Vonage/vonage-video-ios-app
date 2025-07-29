//
//  Created by Vonage on 29/7/25.
//

import Foundation
import VERACore

class MockSessionRepository: SessionRepository {
    var currentCall: (any VERACore.CallFacade)?

    func createSession(
        _ credentials: VERACore.RoomCredentials
    ) async -> any VERACore.CallFacade {
        let call = MockCall()
        self.currentCall = call
        return call
    }

    func clearSession() {
        self.currentCall = nil
    }
}
