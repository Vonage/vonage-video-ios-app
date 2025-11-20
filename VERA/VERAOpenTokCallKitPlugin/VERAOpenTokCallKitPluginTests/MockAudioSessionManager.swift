//
//  Created by Vonage on 20/11/25.
//

import AVFoundation
import OpenTok

@testable import VERAOpenTokCallKitPlugin

final class MockAudioSessionManager: NSObject, OTAudioSessionManager {

    enum Action: Equatable {
        case preconfigureAudioSession
        case audioSessionDidActivate
        case audioSessionDidDeactivate
        case callingServicesModeEnabled
    }

    var recordedActions: [Action] = []

    func preconfigureAudioSessionForCall(withMode mode: AVAudioSession.Mode?) {
        recordedActions.append(.preconfigureAudioSession)
    }

    func audioSessionDidActivate(_ session: AVAudioSession) {
        recordedActions.append(.audioSessionDidActivate)
    }

    func audioSessionDidDeactivate(_ session: AVAudioSession) {
        recordedActions.append(.audioSessionDidDeactivate)
    }

    func enableCallingServicesMode() {
        recordedActions.append(.callingServicesModeEnabled)
    }
}
