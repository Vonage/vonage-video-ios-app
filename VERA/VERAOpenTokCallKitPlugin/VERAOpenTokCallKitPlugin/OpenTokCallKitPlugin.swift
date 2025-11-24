//
//  Created by Vonage on 13/10/25.
//

import CallKit
import Foundation
import OpenTok
import VERACore
import VERAOpenTok

public final class OpenTokCallKitPlugin: OpenTokPlugin, OpenTokPluginCallHolder {
    public enum Error: Swift.Error {
        case invalidCallID
    }

    public weak var call: (any VERACore.CallFacade)?

    var callManager: VERACallManager!
    var sessionManager: OTAudioSessionManager!
    var providerDelegate: ProviderDelegate?
    var currentCallID: UUID?

    public var pluginIdentifier: String { String(describing: type(of: self)) }

    public init() {}

    public func callDidStart(_ userInfo: [String: Any]) async throws {
        let roomName = userInfo[OpenTokCallParams.roomName.rawValue] as? String ?? ""
        let callID = userInfo[OpenTokCallParams.callID.rawValue] as? String ?? ""

        if let callUUID = UUID(uuidString: callID) {
            currentCallID = callUUID
            try await callManager.startCall(handle: roomName, callID: callUUID)
            providerDelegate?.reportConnected(callUUID: callUUID)
            providerDelegate?.setupHold(to: callUUID)
        } else {
            throw Error.invalidCallID
        }
    }

    public func callDidEnd() async throws {
        guard let currentCallID = currentCallID else { return }
        self.currentCallID = nil
        try await callManager.end(callID: currentCallID)
    }

    public func setup() {
        callManager = VERACallManager()
        sessionManager = OTAudioDeviceManager.currentAudioSessionManager()
        sessionManager?.enableCallingServicesMode()
        providerDelegate = ProviderDelegate(sessionManager: sessionManager)
        providerDelegate?.onEndCall = { [weak self] in
            Task { [weak self] in
                guard let self else { return }
                if let isOnHold = self.call?.isOnHold, isOnHold {
                    // Ignore end call event
                } else {
                    self.currentCallID = nil
                    try? await self.call?.disconnect()
                }
            }
        }
        providerDelegate?.onProviderReset = { [weak self] in
            Task { [weak self] in
                self?.currentCallID = nil
                try? await self?.call?.disconnect()
            }
        }
        providerDelegate?.onHold = { [weak self] isOnHold in
            self?.call?.setOnHold(isOnHold)
        }
        providerDelegate?.onMute = { [weak self] isMuted in
            self?.call?.muteLocalMedia(isMuted)
        }
    }
}
