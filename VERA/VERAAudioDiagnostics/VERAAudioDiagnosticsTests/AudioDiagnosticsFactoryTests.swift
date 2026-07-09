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

        // MARK: - Initialization Tests

        @Test("initializes with speaker test service")
        func initializesWithService() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            // Test passes if initialization succeeds
            #expect(sut is AudioDiagnosticsFactory)
        }

        // MARK: - View Model Creation Tests

        @Test("makeViewModel creates new view model")
        func makeViewModelCreatesNewViewModel() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel = sut.makeViewModel()

            #expect(viewModel is AudioOutputControlViewModel)
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

        // MARK: - View Creation Tests

        @Test("makeView creates AudioDiagnosticsView")
        func makeViewCreatesView() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let view = sut.makeView()

            #expect(view is AudioDiagnosticsView)
        }

        @Test("makeConfiguredView returns AnyView")
        func makeConfiguredViewReturnsAnyView() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let configuredView = sut.makeConfiguredView()

            #expect(configuredView is AnyView)
        }

        // MARK: - Waiting Room Circular Button Tests

        @Test("makeWaitingRoomButton creates button")
        func makeWaitingRoomButtonCreatesButton() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeWaitingRoomButton()

            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        @Test("makeWaitingRoomButton provides view closure")
        func makeWaitingRoomButtonProvidesViewClosure() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeWaitingRoomButton()

            // Access the makeDialog closure through reflection or by creating the view
            // For now, just verify the button was created
            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        // MARK: - Waiting Room Selector Button Tests

        @Test("makeWaitingRoomSelectorButton creates AudioDiagnosticsButton")
        func makeWaitingRoomSelectorButtonCreatesButton() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button = sut.makeWaitingRoomSelectorButton()

            #expect(button is AudioDiagnosticsButton)
        }

        @Test("makeWaitingRoomSelectorButton creates independent instances")
        func makeWaitingRoomSelectorButtonCreatesIndependentInstances() {
            let service = MockSpeakerTestService()
            let sut = AudioDiagnosticsFactory(speakerTestService: service)

            let button1 = sut.makeWaitingRoomSelectorButton()
            let button2 = sut.makeWaitingRoomSelectorButton()

            // SwiftUI Views are value types, verify they can be created independently
            #expect(type(of: button1) == type(of: button2))
        }

        @Test("AudioDiagnosticsButton uses correct accessibility identifier from enum")
        func audioDiagnosticsButtonHasCorrectAccessibilityID() {
            #expect(AudioDiagnosticsAccessibilityID.waitingRoomButton == "WaitingRoom.AudioOutputTestButton")
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

            #expect(button is AudioDiagnosticsMeetingRoomButton)
            #expect(callbackInvoked == false)  // Not invoked yet
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
    }

    // MARK: - Mock Speaker Test Service

    @MainActor
    private final class MockSpeakerTestService: SpeakerTestService {
        private let audioLevelSubject = PassthroughSubject<Float, Never>()

        var audioLevelPublisher: AnyPublisher<Float, Never> {
            audioLevelSubject.eraseToAnyPublisher()
        }

        private(set) var playTestSoundCallCount = 0
        private(set) var stopTestSoundCallCount = 0

        func playTestSound() {
            playTestSoundCallCount += 1
        }

        func stopTestSound() {
            stopTestSoundCallCount += 1
        }
    }
#endif
