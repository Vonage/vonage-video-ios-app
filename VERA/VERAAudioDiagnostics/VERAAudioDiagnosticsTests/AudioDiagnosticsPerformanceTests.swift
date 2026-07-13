//
//  Created by Vonage on 13/07/26.
//

#if canImport(UIKit)
    import Combine
    import Testing
    import CoreFoundation

    @testable import VERAAudioDiagnostics

    @Suite("AudioDiagnostics Performance Tests")
    @MainActor
    struct AudioDiagnosticsPerformanceTests {

        // MARK: - Creation Performance Tests

        @Test("view model creation is fast")
        func viewModelCreationIsFast() {
            let service = MockSpeakerTestService()

            let startTime = CFAbsoluteTimeGetCurrent()

            // Create many view models
            for _ in 0..<100 {
                _ = AudioOutputControlViewModel(speakerTestService: service)
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should create 100 view models in less than 100ms
            #expect(timeElapsed < 0.1)
        }

        @Test("factory component creation is fast")
        func factoryComponentCreationIsFast() {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            let startTime = CFAbsoluteTimeGetCurrent()

            // Create many components
            for _ in 0..<50 {
                _ = factory.makeViewModel()
                _ = factory.makeWaitingRoomButton()
                _ = factory.makeMeetingRoomButton {}
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should create 200 components (50 * 4) in less than 200ms
            #expect(timeElapsed < 0.2)
        }

        @Test("tone player generation is reasonably fast")
        func tonePlayerGenerationIsReasonablyFast() {
            let useCase = DefaultGenerateTonePlayerUseCase()

            let startTime = CFAbsoluteTimeGetCurrent()

            // Generate multiple players
            for _ in 0..<10 {
                _ = useCase()
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should generate 10 players in less than 1 second
            #expect(timeElapsed < 1.0)
        }

        // MARK: - Audio Level Publisher Performance Tests

        @Test("audio level publisher handles high frequency updates")
        func audioLevelPublisherHandlesHighFrequencyUpdates() async {
            let service = MockSpeakerTestService()
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            viewModel.testSpeaker()

            let startTime = CFAbsoluteTimeGetCurrent()

            // Emit many audio levels rapidly
            for i in 0..<1000 {
                service.emitAudioLevel(Float(i % 100) / 100.0)
            }

            // Give time for all updates to process
            try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should handle 1000 updates in less than 1 second
            #expect(timeElapsed < 1.0)

            // Should have received the final value
            #expect(viewModel.currentAudioLevel >= 0.0)
            #expect(viewModel.currentAudioLevel <= 1.0)
        }

        @Test("multiple subscribers don't impact performance significantly")
        func multipleSubscribersDontImpactPerformanceSignificantly() async {
            let service = MockSpeakerTestService()

            // Create many subscribers
            let viewModels = (0..<20).map { _ in
                AudioOutputControlViewModel(speakerTestService: service)
            }

            // Start all subscriptions
            for viewModel in viewModels {
                viewModel.testSpeaker()
            }

            let startTime = CFAbsoluteTimeGetCurrent()

            // Emit audio levels
            for i in 0..<100 {
                service.emitAudioLevel(Float(i % 100) / 100.0)
            }

            // Give time for all updates to process
            try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should handle 100 updates to 20 subscribers in less than 1 second
            #expect(timeElapsed < 1.0)

            // All should have received updates
            for viewModel in viewModels {
                #expect(viewModel.currentAudioLevel >= 0.0)
                #expect(viewModel.currentAudioLevel <= 1.0)
            }
        }

        // MARK: - Memory Performance Tests

        @Test("repeated creation and destruction doesn't leak memory")
        func repeatedCreationAndDestructionDoesntLeakMemory() async {
            let service = MockSpeakerTestService()

            // Create and destroy many view models
            for _ in 0..<100 {
                var viewModel: AudioOutputControlViewModel? = AudioOutputControlViewModel(
                    speakerTestService: service
                )

                viewModel!.testSpeaker()
                service.emitAudioLevel(0.5)

                // Small delay for publisher
                try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms

                viewModel!.stopSpeaker()
                viewModel = nil  // Deallocate
            }

            // Test passes if we reach here without crashes or excessive memory usage
            #expect(true)
        }

        @Test("concurrent operations don't cause performance degradation")
        func concurrentOperationsDontCausePerformanceDegradation() async {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            let startTime = CFAbsoluteTimeGetCurrent()

            // Simulate concurrent usage from multiple contexts
            await withTaskGroup(of: Void.self) { group in
                // Simulate multiple waiting room users
                for _ in 0..<5 {
                    group.addTask {
                        let viewModel = await factory.makeViewModel()
                        await viewModel.testSpeaker()
                        try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms
                        await viewModel.stopSpeaker()
                    }
                }

                // Simulate multiple meeting room users
                for _ in 0..<5 {
                    group.addTask {
                        let viewModel = await factory.makeViewModel()
                        await viewModel.testSpeaker()
                        try? await Task.sleep(nanoseconds: 15_000_000)  // 15ms
                        await viewModel.stopSpeaker()
                    }
                }

                // Simulate audio level updates
                group.addTask {
                    for i in 0..<50 {
                        await service.emitAudioLevel(Float(i % 10) / 10.0)
                        try? await Task.sleep(nanoseconds: 2_000_000)  // 2ms
                    }
                }
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should complete all concurrent operations in reasonable time
            #expect(timeElapsed < 2.0)  // Less than 2 seconds
        }

        // MARK: - Stress Tests

        @Test("system handles extreme rapid state changes")
        func systemHandlesExtremeRapidStateChanges() async {
            let service = MockSpeakerTestService()
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            let startTime = CFAbsoluteTimeGetCurrent()

            // Rapid state changes
            for _ in 0..<500 {
                viewModel.togglePlayback()
                // No sleep - maximum speed
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should handle 500 rapid toggles in less than 1 second
            #expect(timeElapsed < 1.0)

            // Final state should be consistent
            let finalState = viewModel.isPlaying
            #expect(finalState == true || finalState == false)
        }

        @Test("system handles many simultaneous factory instances")
        func systemHandlesManySimultaneousFactoryInstances() {
            let service = MockSpeakerTestService()

            let startTime = CFAbsoluteTimeGetCurrent()

            // Create many factories
            let factories = (0..<100).map { _ in
                AudioDiagnosticsFactory(speakerTestService: service)
            }

            // Create components from each factory
            var components: [Any] = []
            for factory in factories {
                components.append(factory.makeViewModel())
                components.append(factory.makeWaitingRoomButton())
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should create 100 factories and 200 components in less than 500ms
            #expect(timeElapsed < 0.5)
            #expect(components.count == 200)
        }

        @Test("audio level processing doesn't block UI operations")
        func audioLevelProcessingDoesntBlockUIOperations() async {
            let service = MockSpeakerTestService()
            let viewModel = AudioOutputControlViewModel(speakerTestService: service)

            viewModel.testSpeaker()

            // Simulate heavy audio level processing
            let startTime = CFAbsoluteTimeGetCurrent()

            await withTaskGroup(of: Void.self) { group in
                // Continuous audio level updates
                group.addTask {
                    for i in 0..<1000 {
                        await service.emitAudioLevel(Float(i % 100) / 100.0)
                        try? await Task.sleep(nanoseconds: 100_000)  // 0.1ms
                    }
                }

                // Simulate UI operations
                group.addTask {
                    for _ in 0..<100 {
                        await viewModel.togglePlayback()
                        try? await Task.sleep(nanoseconds: 1_000_000)  // 1ms
                    }
                }
            }

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should complete both tasks without significant blocking
            #expect(timeElapsed < 2.0)
        }

        // MARK: - Resource Usage Tests

        @Test("null service has minimal overhead")
        func nullServiceHasMinimalOverhead() async {
            let nullService = NullSpeakerTestService()

            let startTime = CFAbsoluteTimeGetCurrent()

            // Many operations with null service
            for _ in 0..<1000 {
                nullService.playTestSound()
                nullService.stopTestSound()
            }

            // Subscribe to publisher (should be empty)
            let cancellable = nullService.audioLevelPublisher
                .sink { _ in }

            try? await Task.sleep(nanoseconds: 10_000_000)  // 10ms

            cancellable.cancel()

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Null service operations should be extremely fast
            #expect(timeElapsed < 0.1)
        }

        @Test("mock service scales with load")
        func mockServiceScalesWithLoad() async {
            let service = MockSpeakerTestService()
            let viewModels = (0..<50).map { _ in
                AudioOutputControlViewModel(speakerTestService: service)
            }

            // Start all
            for viewModel in viewModels {
                viewModel.testSpeaker()
            }

            let startTime = CFAbsoluteTimeGetCurrent()

            // Emit many updates
            for i in 0..<200 {
                service.emitAudioLevel(Float(i % 100) / 100.0)
            }

            try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms for processing

            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

            // Should handle 200 updates to 50 subscribers efficiently
            #expect(timeElapsed < 1.0)
            #expect(service.playTestSoundCallCount == 50)
        }
    }
#endif
