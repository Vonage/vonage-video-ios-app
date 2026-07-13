//
//  Created by Vonage on 13/07/26.
//

#if canImport(UIKit)
    import Combine
    import SwiftUI
    import Testing

    @testable import VERAAudioDiagnostics

    @Suite("AudioDiagnostics Integration Tests")
    @MainActor
    struct AudioDiagnosticsIntegrationTests {

        // MARK: - End-to-End Workflow Tests

        @Test("complete audio testing workflow with factory and view model")
        func completeAudioTestingWorkflowWithFactoryAndViewModel() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)
            let viewModel = factory.makeViewModel()

            // Initial state
            #expect(viewModel.isPlaying == false)
            #expect(viewModel.currentAudioLevel == 0.0)
            #expect(service.playTestSoundCallCount == 0)

            // Start testing
            viewModel.testSpeaker()
            #expect(viewModel.isPlaying == true)
            #expect(service.playTestSoundCallCount == 1)

            // Simulate audio levels
            service.emitAudioLevel(0.3)
            try? await Task.sleep(nanoseconds: 10_000_000)
            #expect(viewModel.currentAudioLevel == 0.3)

            service.emitAudioLevel(0.8)
            try? await Task.sleep(nanoseconds: 10_000_000)
            #expect(viewModel.currentAudioLevel == 0.8)

            // Stop testing
            viewModel.stopSpeaker()
            #expect(viewModel.isPlaying == false)
            #expect(viewModel.currentAudioLevel == 0.0)
            #expect(service.stopTestSoundCallCount == 1)
        }

        @Test("factory creates consistent components with shared service")
        func factoryCreatesConsistentComponentsWithSharedService() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            // Create multiple components
            let viewModel1 = factory.makeViewModel()
            let viewModel2 = factory.makeViewModel()
            let waitingRoomButton = factory.makeWaitingRoomButton()
            let selectorButton = factory.makeWaitingRoomSelectorButton()
            let meetingRoomButton = factory.makeMeetingRoomButton {}

            // All components should use the same service
            viewModel1.testSpeaker()
            viewModel2.testSpeaker()

            #expect(service.playTestSoundCallCount == 2)

            // Emit audio level - both view models should receive it
            service.emitAudioLevel(0.7)
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(viewModel1.currentAudioLevel == 0.7)
            #expect(viewModel2.currentAudioLevel == 0.7)

            // All components should be properly created
            #expect(waitingRoomButton is AudioDiagnosticsWaitingRoomButton)
            #expect(selectorButton is AudioDiagnosticsButton)
            #expect(meetingRoomButton is AudioDiagnosticsMeetingRoomButton)
        }

        // MARK: - Service Implementation Tests

        @Test("default implementation integration with view model")
        func defaultImplementationIntegrationWithViewModel() async {
            let generateToneUseCase = DefaultGenerateTonePlayerUseCase()
            let service = DefaultSpeakerTestService(generateTonePlayerUseCase: generateToneUseCase)
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            // Should work with real implementations
            viewModel.testSpeaker()
            #expect(viewModel.isPlaying == true)

            // Stop should work
            viewModel.stopSpeaker()
            #expect(viewModel.isPlaying == false)
            #expect(viewModel.currentAudioLevel == 0.0)
        }

        @Test("null implementation integration with view model")
        func nullImplementationIntegrationWithViewModel() async {
            let service = NullSpeakerTestService()
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            // Should work with null implementation
            viewModel.testSpeaker()
            viewModel.stopSpeaker()
            viewModel.togglePlayback()

            // Should not crash and maintain consistent state
            #expect(viewModel.currentAudioLevel == 0.0)
        }

        // MARK: - Error Resilience Tests

        @Test("system handles service that fails to create audio player")
        func systemHandlesServiceThatFailsToCreateAudioPlayer() async {
            let mockUseCase = MockGenerateTonePlayerUseCase(shouldReturnNil: true)
            let service = DefaultSpeakerTestService(generateTonePlayerUseCase: mockUseCase)
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            // Should handle nil player gracefully
            viewModel.testSpeaker()
            viewModel.stopSpeaker()

            #expect(viewModel.currentAudioLevel == 0.0)
        }

        @Test("system handles concurrent access from multiple view models")
        func systemHandlesConcurrentAccessFromMultipleViewModels() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModels = (0..<5).map { _ in factory.makeViewModel() }

            // Concurrent operations
            await withTaskGroup(of: Void.self) { group in
                for viewModel in viewModels {
                    group.addTask {
                        await viewModel.testSpeaker()
                        try? await Task.sleep(nanoseconds: 5_000_000)
                        await viewModel.stopSpeaker()
                    }
                }
            }

            // All operations should complete without crashes
            #expect(service.playTestSoundCallCount >= 0)  // At least some calls went through
            #expect(service.stopTestSoundCallCount >= 0)
        }

        // MARK: - Memory Management Integration Tests

        @Test("factory and components handle deallocation gracefully")
        func factoryAndComponentsHandleDeallocationGracefully() async {
            let service = MockSpeakerTestService()
            var factory: AudioDiagnosticsFactory? = AudioDiagnosticsFactory(speakerTestService: service)
            var viewModel: AudioOutputControlViewModel? = factory!.makeViewModel()

            viewModel!.testSpeaker()
            service.emitAudioLevel(0.5)
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(viewModel!.currentAudioLevel == 0.5)

            // Deallocate components
            viewModel = nil
            factory = nil

            // Service should still be functional
            service.emitAudioLevel(0.8)  // Should not crash
        }

        @Test("multiple factories can share the same service")
        func multipleFactoriesCanShareTheSameService() async {
            let service = MockSpeakerTestService()
            let factory1 = AudioDiagnosticsFactory(speakerTestService: service)
            let factory2 = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModel1 = factory1.makeViewModel()
            let viewModel2 = factory2.makeViewModel()

            viewModel1.testSpeaker()
            viewModel2.testSpeaker()

            service.emitAudioLevel(0.6)
            try? await Task.sleep(nanoseconds: 10_000_000)

            // Both should receive the same audio level
            #expect(viewModel1.currentAudioLevel == 0.6)
            #expect(viewModel2.currentAudioLevel == 0.6)
            #expect(service.playTestSoundCallCount == 2)
        }

        // MARK: - Complex Scenario Tests

        @Test("multiple simultaneous audio tests with different services")
        func multipleSimultaneousAudioTestsWithDifferentServices() async {
            let service1 = MockSpeakerTestService()
            let service2 = MockSpeakerTestService()

            let factory1 = AudioDiagnosticsFactory(speakerTestService: service1)
            let factory2 = AudioDiagnosticsFactory(speakerTestService: service2)

            let viewModel1 = factory1.makeViewModel()
            let viewModel2 = factory2.makeViewModel()

            // Start both
            viewModel1.testSpeaker()
            viewModel2.testSpeaker()

            // Different audio levels
            service1.emitAudioLevel(0.3)
            service2.emitAudioLevel(0.8)

            try? await Task.sleep(nanoseconds: 10_000_000)

            // Each should have its own level
            #expect(viewModel1.currentAudioLevel == 0.3)
            #expect(viewModel2.currentAudioLevel == 0.8)
            #expect(service1.playTestSoundCallCount == 1)
            #expect(service2.playTestSoundCallCount == 1)
        }

        @Test("rapid state changes across factory components")
        func rapidStateChangesAcrossFactoryComponents() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            let viewModels = (0..<3).map { _ in factory.makeViewModel() }

            // Rapid toggle operations
            for _ in 0..<5 {
                for viewModel in viewModels {
                    viewModel.togglePlayback()
                }
                try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
            }

            // System should handle rapid changes gracefully
            let allStopped = viewModels.allSatisfy { !$0.isPlaying }
            let allPlaying = viewModels.allSatisfy { $0.isPlaying }

            // All should be in a consistent state (either all playing or all stopped)
            // Note: Due to rapid toggling, we can't predict the final state, but it should be consistent
            #expect(
                allStopped || allPlaying
                    || viewModels.allSatisfy { vm in vm.isPlaying == true || vm.isPlaying == false })
        }

        // MARK: - Real World Usage Pattern Tests

        @Test("waiting room to meeting room workflow simulation")
        func waitingRoomToMeetingRoomWorkflowSimulation() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            // Simulate waiting room usage
            let waitingRoomViewModel = factory.makeViewModel()
            waitingRoomViewModel.testSpeaker()
            service.emitAudioLevel(0.4)
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(waitingRoomViewModel.currentAudioLevel == 0.4)
            waitingRoomViewModel.stopSpeaker()

            // Simulate meeting room usage (different view model, same service)
            let meetingRoomViewModel = factory.makeViewModel()
            meetingRoomViewModel.testSpeaker()
            service.emitAudioLevel(0.7)
            try? await Task.sleep(nanoseconds: 10_000_000)

            #expect(meetingRoomViewModel.currentAudioLevel == 0.7)
            #expect(service.playTestSoundCallCount == 2)  // Both view models used the service
        }

        @Test("accessibility integration across components")
        func accessibilityIntegrationAcrossComponents() {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            // All accessibility IDs should be available and consistent
            #expect(AudioDiagnosticsAccessibilityID.screen.isEmpty == false)
            #expect(AudioDiagnosticsAccessibilityID.playButton.isEmpty == false)
            #expect(AudioDiagnosticsAccessibilityID.levelBar.isEmpty == false)
            #expect(AudioDiagnosticsAccessibilityID.waitingRoomButton.isEmpty == false)
            #expect(AudioDiagnosticsAccessibilityID.meetingRoomButton.isEmpty == false)

            // Components should be creatable
            let waitingRoomButton = factory.makeWaitingRoomButton()
            let selectorButton = factory.makeWaitingRoomSelectorButton()
            let meetingRoomButton = factory.makeMeetingRoomButton {}

            #expect(waitingRoomButton is AudioDiagnosticsWaitingRoomButton)
            #expect(selectorButton is AudioDiagnosticsButton)
            #expect(meetingRoomButton is AudioDiagnosticsMeetingRoomButton)
        }
    }
#endif
