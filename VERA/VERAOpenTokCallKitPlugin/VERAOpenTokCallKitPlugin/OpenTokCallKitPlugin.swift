//
//  Created by Vonage on 13/10/25.
//

import CallKit
import Foundation
import OpenTok
import VERAOpenTok

public final class OpenTokCallKitPlugin: OpenTokPlugin, OpenTokPluginCallHolder {

    public var channel: (any VERAOpenTok.OpenTokSignalChannel)?
    public var call: OpenTokCall?

    lazy var callManager = VERACallManager()
    lazy var sessionManager = OTAudioDeviceManager.currentAudioSessionManager()
    var providerDelegate: ProviderDelegate?
    var currentCallID: UUID?

    public init() {
    }

    public func handleSignal(_ signal: VERAOpenTok.OpenTokSignal) {}

    public func callDidStart(_ userInfo: [String: Any]) {
        let roomName = userInfo[OpenTokCallParams.roomName.rawValue] as? String ?? ""
        let callID = userInfo[OpenTokCallParams.callID.rawValue] as? String ?? ""

        if let callUUID = UUID(uuidString: callID) {
            currentCallID = callUUID
            callManager.startCall(handle: roomName, callID: callUUID)
        } else {
            assertionFailure("callID is not a valid UUID")
        }
    }

    public func callDidEnd() {
        guard let currentCallID = currentCallID else { return }
        self.currentCallID = nil
        callManager.end(callID: currentCallID)
    }

    func sendMessage(_ message: String) throws {
    }

    public func setup() {
        sessionManager?.enableCallingServicesMode()
        providerDelegate = ProviderDelegate(sessionManager: sessionManager)
        providerDelegate?.onEndCall = { [weak self] in
            Task { [weak self] in
                try? await self?.call?.disconnect()
            }
        }
        providerDelegate?.onProviderReset = { [weak self] in
            Task { [weak self] in
                try? await self?.call?.disconnect()
            }
        }
    }
}
