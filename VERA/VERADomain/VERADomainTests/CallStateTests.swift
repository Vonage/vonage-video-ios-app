//
//  Created by Vonage on 13/10/2026.
//

import Testing
import VERADomain

@Suite("Call state concurrency")
struct CallStateTests {

    @Test("All call states retain their case across task boundaries")
    func statesAcrossTasks() async {
        let states: [CallState] = [.idle, .connecting, .connected, .disconnecting, .disconnected]

        for state in states {
            let received = await Task.detached { state }.value

            switch (state, received) {
            case (.idle, .idle), (.connecting, .connecting), (.connected, .connected),
                (.disconnecting, .disconnecting), (.disconnected, .disconnected):
                break
            default:
                Issue.record("Call state changed during task transfer")
            }
        }
    }
}
