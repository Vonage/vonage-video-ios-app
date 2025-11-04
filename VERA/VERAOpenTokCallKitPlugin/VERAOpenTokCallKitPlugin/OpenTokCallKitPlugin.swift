//
//  Created by Vonage on 13/10/25.
//

import CallKit
import Foundation
import VERAOpenTok
import OpenTok

public final class OpenTokCallKitPlugin: OpenTokPlugin {

    public var channel: (any VERAOpenTok.OpenTokSignalChannel)?

    lazy var sessionManager = OTAudioDeviceManager.currentAudioSessionManager()
    var providerDelegate: ProviderDelegate?
    
    public init() {
    }

    public func handleSignal(_ signal: VERAOpenTok.OpenTokSignal) {}

    public func callDidStart(_ userInfo: [String: Any]) {
    }

    public func callDidEnd() {
    }

    func sendMessage(_ message: String) throws {
    }
    
    public func setup() {
        sessionManager?.enableCallingServicesMode()
        providerDelegate = ProviderDelegate(sessionManager: sessionManager)
    }
}
