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

/// A minimal protocol to abstract `CXProvider` for testing.
///
/// Conformers forward CallKit provider events and reports without tying consumers
/// to the concrete `CXProvider` type, enabling dependency injection and unit tests.
///
/// - SeeAlso: ``ProviderDelegate``
protocol CXProviderProtocol {
    func setDelegate(_ delegate: CXProviderDelegate?, queue: DispatchQueue?)
    func reportCall(with UUID: UUID, updated update: CXCallUpdate)
    func reportOutgoingCall(with UUID: UUID, startedConnectingAt: Date?)
    func reportOutgoingCall(with UUID: UUID, connectedAt: Date?)
}

extension CXProvider: CXProviderProtocol {}

/// Bridges CallKit `CXProvider` events to higher-level call controls.
///
/// `ProviderDelegate` owns a `CXProviderProtocol` instance, configures system capabilities,
/// and forwards CallKit actions (start, end, hold, mute, activate/deactivate) via
/// simple closures so the call façade or plugins can react accordingly.
///
/// ## Responsibilities
/// - Configure a provider with app capabilities (icon, video support, handle types)
/// - Pre-heat and manage the `AVAudioSession` using Vonage’s audio session manager
/// - Translate CallKit actions to closures: `onEndCall`, `onProviderReset`, `onHold`, `onMute`
/// - Report connection state and enable holding on the active call
///
/// - Important: Use `sessionManager.preconfigureAudioSessionForCall(withMode:)` during start call
///   to ensure proper audio activation for system-elevated sessions.
/// - SeeAlso: ``CXProviderProtocol``
final class ProviderDelegate: NSObject, CXProviderDelegate {

    /// The underlying CallKit provider abstraction.
    private let provider: CXProviderProtocol
    /// Manages audio session configuration and lifecycle in Calling Services mode.
    private let sessionManager: OTAudioSessionManager?

    /// Closure invoked to end an ongoing call.
    ///
    /// Set by consumers to trigger teardown (e.g., façade `disconnect()`).
    var onEndCall: (() -> Void)?
    /// Closure invoked when the provider resets.
    ///
    /// Use to end active calls and clear state; sessions are no longer valid.
    var onProviderReset: (() -> Void)?
    /// Closure invoked when CallKit toggles hold.
    ///
    /// - Parameter isOnHold: `true` to place on hold; `false` to resume.
    var onHold: ((Bool) -> Void)?
    /// Closure invoked when CallKit toggles mute.
    ///
    /// - Parameter isMuted: `true` to mute local media; `false` to unmute.
    var onMute: ((Bool) -> Void)?

    /// Creates a provider delegate.
    ///
    /// - Parameters:
    ///   - provider: Optional provider implementation. Defaults to a `CXProvider`
    ///     configured with ``providerConfiguration``.
    ///   - sessionManager: Optional Vonage audio session manager to handle activation and mode.
    ///
    /// The created provider sets its delegate to this instance.
    init(
        provider: CXProviderProtocol? = nil,
        sessionManager: OTAudioSessionManager? = nil
    ) {
        self.sessionManager = sessionManager
        self.provider = provider ?? CXProvider(configuration: Self.providerConfiguration)

        super.init()

        self.provider.setDelegate(self, queue: nil)
    }

    /// The app's CallKit provider configuration.
    ///
    /// Configures:
    /// - Template icon from `VERACommonUIAsset.Images.callKitIcon`
    /// - Video support enabled
    /// - Single call per group and single group
    /// - Generic handle types (room name as handle)
    ///
    /// - Returns: A `CXProviderConfiguration` ready for `CXProvider`.
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

    /// Called when the provider begins handling transactions.
    func providerDidBegin(_ provider: CXProvider) {
        print("Provider did begin")
    }

    /// Called when the provider is reset by the system.
    ///
    /// Ends any ongoing calls and clears state via ``onProviderReset``.
    func providerDidReset(_ provider: CXProvider) {
        print("Provider did reset")
        /**
         *   End any ongoing calls if the provider resets, and remove them from the app's list of calls,
         *   since they are no longer valid.
         */
        onProviderReset?()
    }

    /// Performs a start-call action, pre-heating the audio session for video chat.
    ///
    /// - Important: Don't start call audio here; wait for system activation
    ///   after priority elevation. See Apple forums thread 64544.
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("Received perform CXStartCallAction \(action.callUUID)")

        /**
         *   Configure the audio session, but do not start call audio here, since it must be done once
         *   the audio session has been activated by the system after having its priority elevated.
         *
         *   https://forums.developer.apple.com/thread/64544
         *   We can't configure the audio session here for the case of launching it from locked screen
         *   instead, we have to pre-heat the AVAudioSession by configuring as early as possible, didActivate do not get called otherwise
         *   please look for  * pre-heat the AVAudioSession *
         */
        sessionManager?.preconfigureAudioSessionForCall(withMode: .videoChat)

        action.fulfill()
    }

    /// Performs an end-call action.
    ///
    /// Invokes ``onEndCall`` to let consumers tear down the session, then fulfills the action.
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("Received perform CXEndCallAction")

        onEndCall?()

        /// Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    /// Performs a set-held action and fulfills it.
    ///
    /// - Parameter action.isOnHold: Current hold state requested by CallKit.
    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        print("Received perform CXSetHeldCallAction \(action.isOnHold)")
        onHold?(action.isOnHold)

        /// Signal to the system that the action has been successfully performed.
        action.fulfill()
    }

    /// Performs a set-muted action and fulfills it.
    ///
    /// - Parameter action.isMuted: Current mute state requested by CallKit.
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        print("Received perform CXSetMutedCallAction \(action.isMuted)")
        onMute?(action.isMuted)

        action.fulfill()
    }

    /// Called when an action times out.
    ///
    /// Use to surface error UI or fallback behavior if necessary.
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        print("Timed out \(#function)")

        action.fulfill()
    }

    /// Called when the system activates the app's audio session for calling.
    ///
    /// Forwards activation to the Vonage session manager.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("Received didActivate")
        sessionManager?.audioSessionDidActivate(audioSession)
    }

    /// Called when the system deactivates the app's audio session.
    ///
    /// Use to restart any non-call audio and clear calling resources.
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("Received didDeactivate")
        sessionManager?.audioSessionDidDeactivate(audioSession)
    }

    // MARK: Helpers

    /// Enables holding capability for a given call and reports video presence.
    ///
    /// - Parameter callUUID: The CallKit identifier to update.
    func setupHold(to callUUID: UUID) {
        let update = CXCallUpdate()
        update.supportsHolding = true
        update.hasVideo = true
        provider.reportCall(with: callUUID, updated: update)
    }

    /// Reports that the specified outgoing call is connected.
    ///
    /// - Parameter callUUID: The CallKit identifier to report as connected.
    func reportConnected(callUUID: UUID) {
        provider.reportOutgoingCall(with: callUUID, connectedAt: Date())
    }
}
