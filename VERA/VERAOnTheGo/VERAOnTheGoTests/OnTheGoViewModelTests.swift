//
//  Created by Vonage on 17/10/26.
//

import Foundation
import Testing

@testable import VERAOnTheGo

@Suite("OnTheGoViewModel Tests")
@MainActor
struct OnTheGoViewModelTests {

    // MARK: - Helpers

    @MainActor
    private final class Harness {
        let provider = FakeMotionActivityProvider()
        let preferences = InMemoryOnTheGoPreferencesRepository()
        let spy = SpyCallActions()
        let scheduler = ManualTimeoutScheduler()
        let viewModel: OnTheGoViewModel

        init(configuration: OnTheGoConfiguration = .init()) {
            viewModel = OnTheGoViewModel(
                configuration: configuration,
                preferences: preferences,
                motionProvider: provider,
                actions: spy.actions,
                scheduleTimeout: scheduler.schedule
            )
        }

        /// Pushes a connected snapshot (camera on, mic on) — the "in a normal
        /// video call" state that enables motion detection.
        func connect() {
            viewModel.update(snapshot: .connected())
        }

        /// Drives the detector past its threshold via the fake provider.
        func emitSustainedMotion() {
            for second in stride(from: 0.0, through: 20.0, by: 5) {
                provider.emit(.make(at: second))
            }
        }
    }

    // MARK: - Detector gating

    @Test("Motion provider starts when connected and all conditions hold")
    func providerStartsWhenConnected() {
        let harness = Harness()
        #expect(!harness.provider.isRunning)

        harness.connect()

        #expect(harness.provider.isRunning)
    }

    @Test("Motion provider stops on disconnect")
    func providerStopsOnDisconnect() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.update(snapshot: .disconnected)

        #expect(!harness.provider.isRunning)
    }

    @Test("Provider never starts when feature is disabled")
    func disabledNeverStarts() {
        let harness = Harness(configuration: .init(isEnabled: false))
        harness.connect()

        #expect(!harness.provider.isRunning)
        #expect(harness.provider.startCount == 0)
    }

    @Test("Provider never starts when autoSuggest is off")
    func autoSuggestOffNeverStarts() {
        let harness = Harness(configuration: .init(autoSuggest: false))
        harness.connect()

        #expect(!harness.provider.isRunning)
        #expect(harness.provider.startCount == 0)
    }

    @Test("Provider never starts when the preference is off")
    func preferenceOffNeverStarts() {
        let harness = Harness()
        harness.preferences.suggestWhenMoving = false
        harness.connect()

        #expect(!harness.provider.isRunning)
        #expect(harness.provider.startCount == 0)
    }

    @Test("Provider stops when the preference is turned off mid-call")
    func preferenceOffStops() {
        let harness = Harness()
        harness.connect()
        #expect(harness.provider.isRunning)

        harness.preferences.suggestWhenMoving = false

        #expect(!harness.provider.isRunning)
    }

    @Test("Provider does not start while disconnected")
    func disconnectedNeverStarts() {
        let harness = Harness()
        harness.viewModel.update(snapshot: .disconnected)

        #expect(!harness.provider.isRunning)
        #expect(harness.provider.startCount == 0)
    }

    @Test("Provider does not start when motion is unavailable")
    func unavailableNeverStarts() {
        let harness = Harness()
        harness.provider.isAvailable = false
        harness.connect()

        #expect(!harness.provider.isRunning)
        #expect(harness.provider.startCount == 0)
    }

    @Test("Provider does not start after the suggestion was declined")
    func suppressedNeverStarts() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        harness.viewModel.declineSuggestion()

        #expect(!harness.provider.isRunning)
    }

    @Test("Provider does not start while active")
    func activeStopsProvider() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()

        #expect(!harness.provider.isRunning)
    }

    // MARK: - Suggestion

    @Test("Sustained motion suggests when all conditions hold")
    func sustainedMotionSuggests() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()

        #expect(harness.viewModel.state == .suggested)
        #expect(harness.scheduler.scheduledInterval == harness.viewModel.configuration.suggestionTimeout)
        #expect(!harness.provider.isRunning)  // stopped once suggested? — see note
    }

    @Test("Sustained motion does not suggest when the camera is already off")
    func noSuggestionWhenCameraOff() {
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: false))
        harness.emitSustainedMotion()

        #expect(harness.viewModel.state == .idle)
    }

    @Test("Suggestion timeout declines the suggestion")
    func timeoutDeclines() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        #expect(harness.viewModel.state == .suggested)

        harness.scheduler.fire()

        #expect(harness.viewModel.state == .idle)
        #expect(harness.viewModel.isSuggestionSuppressedForThisCall)
        #expect(!harness.provider.isRunning)
    }

    @Test("Declining suppresses the suggestion for this call")
    func declineSuppresses() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        harness.viewModel.declineSuggestion()

        #expect(harness.viewModel.state == .idle)
        #expect(harness.viewModel.isSuggestionSuppressedForThisCall)

        // New motion does not re-suggest within the same call.
        for second in stride(from: 100.0, through: 160.0, by: 5) {
            harness.provider.emit(.make(at: second))
        }
        #expect(harness.viewModel.state == .idle)
    }

    @Test("Reconnecting clears the suppression")
    func reconnectResetsSuppression() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        harness.viewModel.declineSuggestion()
        #expect(harness.viewModel.isSuggestionSuppressedForThisCall)

        harness.viewModel.update(snapshot: .disconnected)
        harness.connect()

        #expect(!harness.viewModel.isSuggestionSuppressedForThisCall)
        #expect(harness.provider.isRunning)
    }

    // MARK: - Enter

    @Test("Entering with camera on turns it off and auto-mutes")
    func enterTurnsOffCameraAndMutes() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        harness.viewModel.acceptSuggestion()

        #expect(harness.viewModel.state == .active)
        #expect(harness.spy.toggleCameraCount == 1)
        #expect(harness.spy.toggleMicCount == 1)
        #expect(!harness.provider.isRunning)
    }

    @Test("Entering with camera already off does not toggle it")
    func enterCameraAlreadyOff() {
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: false))
        harness.viewModel.enterManually()

        #expect(harness.viewModel.state == .active)
        #expect(harness.spy.toggleCameraCount == 0)
    }

    @Test("Entering with mic already muted does not toggle it")
    func enterMicAlreadyMuted() {
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(isMicEnabled: false))
        harness.viewModel.enterManually()

        #expect(harness.spy.toggleMicCount == 0)
    }

    @Test("enterManually works with autoSuggest off and never starts the provider")
    func enterManuallyWithoutAutoSuggest() {
        let harness = Harness(configuration: .init(autoSuggest: false))
        harness.connect()
        harness.viewModel.enterManually()

        #expect(harness.viewModel.state == .active)
        #expect(harness.provider.startCount == 0)
    }

    @Test("enterManually works while the suggestion is suppressed")
    func enterManuallyWhileSuppressed() {
        let harness = Harness()
        harness.connect()
        harness.emitSustainedMotion()
        harness.viewModel.declineSuggestion()
        harness.viewModel.enterManually()

        #expect(harness.viewModel.state == .active)
    }

    // MARK: - Exit

    @Test("Exit restores the camera when it was on at entry and is still off")
    func exitRestoresCamera() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        // Host reports camera now off as a result of the toggle.
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: false))
        harness.viewModel.exit()

        #expect(harness.spy.toggleCameraCount == 2)  // one at entry, one to restore
        #expect(harness.viewModel.state == .idle)
        #expect(harness.viewModel.isSuggestionSuppressedForThisCall)
    }

    @Test("Exit does not restore the camera when it was already off at entry")
    func exitNoRestoreWhenOffAtEntry() {
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: false))
        harness.viewModel.enterManually()
        harness.viewModel.exit()

        #expect(harness.spy.toggleCameraCount == 0)
    }

    @Test("Exit does not restore the camera when the user re-enabled it while active")
    func exitNoRestoreWhenReEnabled() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        // Camera off from entry, then user turned it back on (e.g. CallKit).
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: false))
        harness.viewModel.update(snapshot: .connected(isCameraEnabled: true))
        harness.viewModel.exit()

        #expect(harness.spy.toggleCameraCount == 1)  // only the entry toggle
    }

    @Test("Exit never touches the mic")
    func exitNeverTouchesMic() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        harness.viewModel.exit()

        #expect(harness.spy.toggleMicCount == 1)  // only the auto-mute at entry
    }

    // MARK: - Mic toggle

    @Test("toggleMic forwards to the host action")
    func toggleMicForwards() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        harness.viewModel.toggleMic()

        #expect(harness.spy.toggleMicCount == 2)
    }

    // MARK: - Disconnect

    @Test("Disconnecting while active resets without calling actions")
    func disconnectWhileActive() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        harness.viewModel.presentSharedContent()
        let callsBefore = (harness.spy.toggleMicCount, harness.spy.toggleCameraCount, harness.spy.endCallCount)

        harness.viewModel.update(snapshot: .disconnected)

        #expect(harness.viewModel.state == .idle)
        #expect(!harness.viewModel.isSuggestionSuppressedForThisCall)
        #expect(!harness.viewModel.isSharedContentPresented)
        #expect(harness.spy.toggleMicCount == callsBefore.0)
        #expect(harness.spy.toggleCameraCount == callsBefore.1)
        #expect(harness.spy.endCallCount == callsBefore.2)
        #expect(!harness.provider.isRunning)
    }

    // MARK: - Shared content

    @Test("Shared content presents and dismisses")
    func sharedContentPresentDismiss() {
        let share = OnTheGoCallSnapshot.Participant(id: "s", name: "Share", isScreenshare: true)
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(screenShareParticipant: share))
        harness.viewModel.enterManually()

        harness.viewModel.presentSharedContent()
        #expect(harness.viewModel.isSharedContentPresented)

        harness.viewModel.dismissSharedContent()
        #expect(!harness.viewModel.isSharedContentPresented)
    }

    @Test("presentSharedContent does nothing without a screen share")
    func presentWithoutShare() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.enterManually()
        harness.viewModel.presentSharedContent()

        #expect(!harness.viewModel.isSharedContentPresented)
    }

    @Test("The sheet dismisses when the screen share disappears")
    func shareDisappearingDismisses() {
        let share = OnTheGoCallSnapshot.Participant(id: "s", name: "Share", isScreenshare: true)
        let harness = Harness()
        harness.viewModel.update(snapshot: .connected(screenShareParticipant: share))
        harness.viewModel.enterManually()
        harness.viewModel.presentSharedContent()
        #expect(harness.viewModel.isSharedContentPresented)

        harness.viewModel.update(snapshot: .connected())

        #expect(!harness.viewModel.isSharedContentPresented)
    }

    // MARK: - Leave call

    @Test("leaveCall forwards to endCall")
    func leaveCallForwards() {
        let harness = Harness()
        harness.connect()
        harness.viewModel.leaveCall()

        #expect(harness.spy.endCallCount == 1)
    }
}
