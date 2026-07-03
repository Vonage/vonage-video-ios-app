//
//  Created by Vonage on 03/07/26.
//

import VERADomain

public final class MockSpeakerTestService: SpeakerTestService {

    public private(set) var playTestSoundCallCount: Int = 0

    public init() {}

    public func playTestSound() {
        playTestSoundCallCount += 1
    }
}
