//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("SessionState tests")
struct SessionStateTests {

    @Test("Initial SessionState has audio and video disabled")
    func initialSessionState() {
        let state = SessionState.initial

        #expect(state.isPublishingAudio == false)
        #expect(state.isPublishingVideo == false)
    }

    @Test("SessionState can be created with custom values")
    func customSessionState() {
        let state = SessionState(isPublishingAudio: true, isPublishingVideo: false)

        #expect(state.isPublishingAudio == true)
        #expect(state.isPublishingVideo == false)
    }

    @Test("SessionState with both enabled")
    func sessionStateBothEnabled() {
        let state = SessionState(isPublishingAudio: true, isPublishingVideo: true)

        #expect(state.isPublishingAudio == true)
        #expect(state.isPublishingVideo == true)
    }
}
