//
//  Created by Vonage on 03/07/26.
//

import VERADomain

final class MockSpeakerTestService: SpeakerTestService {
    private(set) var playTestSoundCallCount: Int = 0

    func playTestSound() {
        playTestSoundCallCount += 1
    }
}
