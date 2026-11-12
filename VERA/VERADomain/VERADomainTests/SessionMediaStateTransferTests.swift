//
//  Created by Vonage on 14/10/2026.
//

import Testing
import VERADomain

@Suite("Media state value transfer")
struct SessionMediaStateTransferTests {

    @Test("Every microphone and camera combination survives task transfer")
    func statesAcrossTasks() async {
        for audio in [false, true] {
            for video in [false, true] {
                let state = SessionState(isPublishingAudio: audio, isPublishingVideo: video)
                let received = await Task.detached { state }.value
                #expect(received.isPublishingAudio == audio)
                #expect(received.isPublishingVideo == video)
            }
        }
    }
}
