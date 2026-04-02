//
//  Created by Vonage on 2/4/26.
//

import Combine
import Foundation
import Testing
import VERADomain

@Suite("Null object pattern tests")
struct NullObjectTests {

    // MARK: - NullAdvancedSettingsUseCase

    @Test("NullAdvancedSettingsUseCase returns empty settings")
    func nullAdvancedSettingsUseCaseReturnsEmptySettings() {
        let useCase = NullAdvancedSettingsUseCase()
        let result = useCase()

        #expect(result.videoResolution == nil)
        #expect(result.videoFrameRate == nil)
        #expect(result.preferredVideoCodecs == nil)
        #expect(result.maxAudioBitrate == nil)
        #expect(result.videoBitratePreset == nil)
        #expect(result.maxVideoBitrate == nil)
        #expect(result.publisherAudioFallbackEnabled == nil)
        #expect(result.subscriberAudioFallbackEnabled == nil)
    }

    // MARK: - NullNoiseSuppressionStatusDataSource

    @Test("NullNoiseSuppressionStatusDataSource emits disabled state")
    func nullNoiseSuppressionEmitsDisabled() async {
        let dataSource = NullNoiseSuppressionStatusDataSource()
        var receivedState: NoiseSuppressionState?
        let cancellable = dataSource.noiseSuppressionState.sink { state in
            receivedState = state
        }

        // Give time for the CurrentValueSubject to emit
        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedState == .disabled)
        _ = cancellable
    }

    @Test("NullNoiseSuppressionStatusDataSource set does nothing")
    func nullNoiseSuppressionSetDoesNothing() async {
        let dataSource = NullNoiseSuppressionStatusDataSource()
        var receivedStates: [NoiseSuppressionState] = []
        let cancellable = dataSource.noiseSuppressionState.sink { state in
            receivedStates.append(state)
        }

        dataSource.set(state: .enabled)

        // Give time for any potential emission
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should still only have the initial disabled value
        #expect(receivedStates == [.disabled])
        _ = cancellable
    }

    // MARK: - NullCaptionsStatusDataSource

    @Test("NullCaptionsStatusDataSource emits disabled state")
    func nullCaptionsEmitsDisabled() async {
        let dataSource = NullCaptionsStatusDataSource()
        var receivedState: CaptionsState?
        let cancellable = dataSource.captionsState.sink { state in
            receivedState = state
        }

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedState == .disabled)
        _ = cancellable
    }

    @Test("NullCaptionsStatusDataSource set does nothing")
    func nullCaptionsSetDoesNothing() async {
        let dataSource = NullCaptionsStatusDataSource()
        var receivedStates: [CaptionsState] = []
        let cancellable = dataSource.captionsState.sink { state in
            receivedStates.append(state)
        }

        dataSource.set(captionsState: .enabled("test"))

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedStates == [.disabled])
        _ = cancellable
    }

    @Test("NullCaptionsStatusDataSource reset does nothing")
    func nullCaptionsResetDoesNothing() async {
        let dataSource = NullCaptionsStatusDataSource()
        var receivedStates: [CaptionsState] = []
        let cancellable = dataSource.captionsState.sink { state in
            receivedStates.append(state)
        }

        dataSource.reset()

        try? await Task.sleep(nanoseconds: 100_000_000)

        #expect(receivedStates == [.disabled])
        _ = cancellable
    }
}
