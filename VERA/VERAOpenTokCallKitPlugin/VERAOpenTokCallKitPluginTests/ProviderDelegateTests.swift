//
//  Created by Vonage on 20/11/25.
//

import AVFoundation
import CallKit
import Foundation
import Testing

@testable import VERAOpenTokCallKitPlugin

@Suite("ProviderDelegate tests")
struct ProviderDelegateTests {

    // MARK: - Initialization Tests

    @Test func initShouldSetDelegateOnProvider() async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        withExtendedLifetime(sut) {
            #expect(mockProvider.recordedActions.contains(.setDelegate))
            #expect(mockProvider.delegate != nil)
            #expect(mockProvider.delegate === sut)
        }
    }

    // MARK: - CXStartCallAction Tests

    @Test func providerPerformStartCallActionShouldPreconfigureAudioSession() async {
        let mockProvider = MockCXProvider()
        let mockSessionManager = MockAudioSessionManager()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: mockSessionManager)

        let action = CXStartCallAction(call: UUID(), handle: CXHandle(type: .generic, value: "test"))

        sut.provider(CXProvider(configuration: .init()), perform: action)

        #expect(mockSessionManager.recordedActions.contains(.preconfigureAudioSession))
    }

    // MARK: - CXEndCallAction Tests

    @Test func providerPerformEndCallActionShouldCallOnEndCallCallback() async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        var onEndCallCalled = false
        sut.onEndCall = {
            onEndCallCalled = true
        }

        let action = CXEndCallAction(call: UUID())
        sut.provider(CXProvider(configuration: .init()), perform: action)

        #expect(onEndCallCalled)
    }

    // MARK: - CXSetHeldCallAction Tests

    @Test(arguments: [true, false])
    func providerPerformSetHeldCallActionShouldCallOnHoldCallback(isOnHold: Bool) async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        var receivedOnHold: Bool?
        sut.onHold = { onHold in
            receivedOnHold = onHold
        }

        let action = CXSetHeldCallAction(call: UUID(), onHold: isOnHold)
        sut.provider(CXProvider(configuration: .init()), perform: action)

        #expect(receivedOnHold == isOnHold)
    }

    // MARK: - CXSetMutedCallAction Tests

    @Test(arguments: [true, false])
    func providerPerformSetMutedCallActionShouldCallOnMuteCallback(isMuted: Bool) async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        var receivedIsMuted: Bool?
        sut.onMute = { muted in
            receivedIsMuted = muted
        }

        let action = CXSetMutedCallAction(call: UUID(), muted: isMuted)
        sut.provider(CXProvider(configuration: .init()), perform: action)

        #expect(receivedIsMuted == isMuted)
    }

    // MARK: - Provider Reset Tests

    @Test func providerDidResetShouldCallOnProviderResetCallback() async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        var onProviderResetCalled = false
        sut.onProviderReset = {
            onProviderResetCalled = true
        }

        sut.providerDidReset(CXProvider(configuration: .init()))

        #expect(onProviderResetCalled)
    }

    // MARK: - Audio Session Tests

    @Test func providerDidActivateAudioSessionShouldNotifySessionManager() async {
        let mockProvider = MockCXProvider()
        let mockSessionManager = MockAudioSessionManager()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: mockSessionManager)

        let audioSession = AVAudioSession.sharedInstance()
        sut.provider(CXProvider(configuration: .init()), didActivate: audioSession)

        #expect(mockSessionManager.recordedActions.contains(.audioSessionDidActivate))
    }

    @Test func providerDidDeactivateAudioSessionShouldNotifySessionManager() async {
        let mockProvider = MockCXProvider()
        let mockSessionManager = MockAudioSessionManager()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: mockSessionManager)

        let audioSession = AVAudioSession.sharedInstance()
        sut.provider(CXProvider(configuration: .init()), didDeactivate: audioSession)

        #expect(mockSessionManager.recordedActions.contains(.audioSessionDidDeactivate))
    }

    // MARK: - Setup Hold Tests

    @Test func setupHoldShouldReportCallWithHoldingSupport() async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        let callUUID = UUID()
        sut.setupHold(to: callUUID)

        let reportCallAction = mockProvider.recordedActions.first { action in
            if case .reportCall(let uuid, _) = action {
                return uuid == callUUID
            }
            return false
        }

        #expect(reportCallAction != nil)
    }

    // MARK: - Callbacks with nil Tests

    @Test func providerActionsWithoutCallbacksShouldNotCrash() async {
        let mockProvider = MockCXProvider()
        let sut = ProviderDelegate(provider: mockProvider, sessionManager: nil)

        // No callbacks set
        #expect(sut.onEndCall == nil)
        #expect(sut.onProviderReset == nil)
        #expect(sut.onHold == nil)
        #expect(sut.onMute == nil)

        // Should not crash
        sut.provider(CXProvider(configuration: .init()), perform: CXEndCallAction(call: UUID()))
        sut.providerDidReset(CXProvider(configuration: .init()))
        sut.provider(CXProvider(configuration: .init()), perform: CXSetHeldCallAction(call: UUID(), onHold: true))
        sut.provider(CXProvider(configuration: .init()), perform: CXSetMutedCallAction(call: UUID(), muted: true))

        // If reached here, no crash occurred
    }

    // MARK: - Provider Configuration Tests

    @Test func providerConfigurationShouldHaveCorrectSettings() async {
        let config = ProviderDelegate.providerConfiguration

        #expect(config.supportsVideo == true)
        #expect(config.maximumCallsPerCallGroup == 1)
        #expect(config.maximumCallGroups == 1)
        #expect(config.supportedHandleTypes == [.generic])
        #expect(config.iconTemplateImageData != nil)
    }
}
