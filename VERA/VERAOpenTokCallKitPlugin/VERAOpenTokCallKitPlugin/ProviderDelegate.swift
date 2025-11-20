//
//  Created by Vonage on 31/10/25.
//

import AVFoundation
import CallKit
import Combine
import Foundation
import OpenTok
import UIKit
import VERACommonUI

protocol CXProviderProtocol {
    func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?)
    func reportCall(with UUID: UUID, updated update: CXCallUpdate)
}

extension CXProvider: CXProviderProtocol {}

final class ProviderDelegate: NSObject, CXProviderDelegate {

    private let provider: CXProviderProtocol
    private let sessionManager: OTAudioSessionManager?

    var onEndCall: (() -> Void)?
    var onProviderReset: (() -> Void)?
    var onHold: ((Bool) -> Void)?
    var onMute: ((Bool) -> Void)?

    init(
        provider: CXProviderProtocol? = nil,
        sessionManager: OTAudioSessionManager? = nil
    ) {
        self.sessionManager = sessionManager
        self.provider = provider ?? CXProvider(configuration: type(of: self).providerConfiguration)

        super.init()

        self.provider.setDelegate(self, queue: nil)
    }

    /// The app's provider configuration, representing its CallKit capabilities
    static var providerConfiguration: CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration()

        let iconImage = VERACommonUIAsset.Images.callKitIcon.image
        providerConfiguration.iconTemplateImageData = iconImage.pngData()
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        providerConfiguration.supportedHandleTypes = [.generic]

        return providerConfiguration
    }

    // MARK: CXProviderDelegate

    func providerDidBegin(_ provider: CXProvider) {
        print("Provider did begin")
    }

    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
        /*
            End any ongoing calls if the provider resets, and remove them from the app's list of calls,
            since they are no longer valid.
         */
        onProviderReset?()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("Received perform CXStartCallAction \(action.callUUID)")

        /*
            Configure the audio session, but do not start call audio here, since it must be done once
            the audio session has been activated by the system after having its priority elevated.
         */
        // https://forums.developer.apple.com/thread/64544
        // we can't configure the audio session here for the case of launching it from locked screen
        // instead, we have to pre-heat the AVAudioSession by configuring as early as possible, didActivate do not get called otherwise
        // please look for  * pre-heat the AVAudioSession *
        sessionManager?.preconfigureAudioSessionForCall(withMode: .videoChat)

        action.fulfill()
    }


    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("Received perform CXEndCallAction")

        onEndCall?()

        //// Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("Received perform CXSetHeldCallAction \(action.isOnHold)")
        onHold?(action.isOnHold)

        /// Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("Received perform CXSetMutedCallAction \(action.isMuted)")
        onMute?(action.isMuted)

        action.fulfill()
    }

    /// React to the action timeout if necessary, such as showing an error UI.
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("Timed out \(#function)")
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Received didActivate")
        sessionManager?.audioSessionDidActivate(audioSession)
    }

    /**
     *    Restart any non-call related audio now that the app's audio session has been
     *    de-activated after having its priority restored to normal.
     */
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Received didDeactivate")
        sessionManager?.audioSessionDidDeactivate(audioSession)
    }

    // MARK: Helpers

    func setupHold(to callUUID: UUID) {
        let update = CXCallUpdate()
        update.supportsHolding = true
        update.hasVideo = true
        provider.reportCall(with: callUUID, updated: update)
    }
}
