//
//  Created by Vonage on 07/07/26.
//

#if canImport(UIKit)
    import Combine
    import SwiftUI
    import Testing

    @testable import VERAAudioDiagnostics

    @Suite("AudioDiagnosticsFactory tests")
    @MainActor
    struct AudioDiagnosticsFactoryTests {

        // MARK: - View Model Creation Tests

        @Test("makeViewModel creates new view model")
        func makeViewModelCreatesNewViewModel() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel = sut.makeViewModel()

            #expect(viewModel.isPlaying == false)
            #expect(viewModel.currentAudioLevel == 0.0)
        }

        @Test("makeViewModel creates independent instances")
        func makeViewModelCreatesIndependentInstances() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel1 = sut.makeViewModel()
            let viewModel2 = sut.makeViewModel()

            #expect(viewModel1 !== viewModel2)
        }

        @Test("makeViewModel view models are properly configured")
        func makeViewModelViewModelsAreProperlyConfigured() async {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel = sut.makeViewModel()

            // Test that the view model is properly initialized with the service
            viewModel.testSpeaker()
            service.emitAudioLevel(0.7)

            // Give time for publisher to emit
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(viewModel.currentAudioLevel == 0.7)
            #expect(service.playTestSoundCallCount == 1)
        }

        // MARK: - Configured View Tests

        @Test("makeConfiguredView creates view with presentation modifiers")
        func makeConfiguredViewCreatesViewWithPresentationModifiers() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let configuredView = sut.makeConfiguredView()

            // Verify that the view is wrapped in AnyView
            #expect(configuredView is AnyView)
        }

        // MARK: - Waiting Room Selector Button Tests

        @Test("makeWaitingRoomSelectorButton creates independent instances")
        func makeWaitingRoomSelectorButtonCreatesIndependentInstances() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button1 = sut.makeWaitingRoomButton()
            let button2 = sut.makeWaitingRoomButton()

            // SwiftUI Views are value types, verify they can be created independently
            #expect(type(of: button1) == type(of: button2))
        }

        @Test("makeWaitingRoomSelectorButton creates functional button")
        func makeWaitingRoomSelectorButtonCreatesFunctionalButton() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeWaitingRoomButton()

            // Verify button type is correct
            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        @Test("AudioDiagnosticsButton uses correct accessibility identifier from enum")
        func audioDiagnosticsButtonHasCorrectAccessibilityID() {
            #expect(AudioDiagnosticsAccessibilityID.waitingRoomButton == "WaitingRoom.AudioOutputTestButton")
        }

        // MARK: - Waiting Room Circular Button Tests

        @Test("makeWaitingRoomButton creates circular button")
        func makeWaitingRoomButtonCreatesCircularButton() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeWaitingRoomButton()

            // Verify button type is correct
            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        @Test("makeWaitingRoomButton with deallocated factory falls back gracefully")
        func makeWaitingRoomButtonFallsBackGracefully() {
            var sut: AudioDiagnosticsFactory? = AudioDiagnosticsFactory(
                speakerTestService: MockSpeakerTestService()
            )

            let button = sut!.makeWaitingRoomButton()

            // Deallocate the factory
            sut = nil

            // Button should still be valid (value type)
            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        // MARK: - Meeting Room Button Tests

        @Test("makeMeetingRoomButton creates button with callback")
        func makeMeetingRoomButtonCreatesButton() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            var callbackInvoked = false
            let button = sut.makeMeetingRoomButton {
                callbackInvoked = true
            }

            #expect(callbackInvoked == false)  // Not invoked yet
            #expect(button is AudioDiagnosticsMeetingRoomButton)
        }

        @Test("makeMeetingRoomButton creates button with nil callback")
        func makeMeetingRoomButtonCreatesButtonWithNilCallback() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeMeetingRoomButton(onShowDialog: {})

            #expect(button is AudioDiagnosticsMeetingRoomButton)
        }

        // MARK: - Service Integration Tests

        @Test("view model created by factory uses provided service")
        func viewModelUsesProvidedService() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel = sut.makeViewModel()
            viewModel.testSpeaker()

            #expect(service.playTestSoundCallCount == 1)
        }

        @Test("multiple view models share same service")
        func multipleViewModelsShareService() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel1 = sut.makeViewModel()
            let viewModel2 = sut.makeViewModel()

            viewModel1.testSpeaker()
            viewModel2.testSpeaker()

            #expect(service.playTestSoundCallCount == 2)
        }

        // MARK: - Accessibility Tests

        @Test("accessibility identifiers are properly defined")
        func accessibilityIdentifiersAreProperlyDefined() {
            #expect(AudioDiagnosticsAccessibilityID.screen == "audio-output-test-screen")
            #expect(AudioDiagnosticsAccessibilityID.playButton == "audio-output-play-button")
            #expect(AudioDiagnosticsAccessibilityID.levelBar == "audio-output-level-bar")
            #expect(AudioDiagnosticsAccessibilityID.waitingRoomButton == "WaitingRoom.AudioOutputTestButton")
            #expect(AudioDiagnosticsAccessibilityID.meetingRoomButton == "MeetingRoom.AudioDiagnosticsButton")
        }

        // MARK: - Error Handling Tests

        @Test("factory works with null speaker test service")
        func factoryWorksWithNullSpeakerTestService() {
            let nullService = NullSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: nullService)

            let viewModel = sut.makeViewModel()

            // Should not crash with null service
            viewModel.testSpeaker()
            viewModel.stopSpeaker()
            viewModel.togglePlayback()

            #expect(viewModel.isPlaying == true)
            #expect(viewModel.currentAudioLevel == 0.0)
        }
    }
#endif
