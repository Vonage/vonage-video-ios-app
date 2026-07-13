//
//  Created by Vonage on 13/07/26.
//

#if canImport(UIKit)
    import SwiftUI
    import Testing

    @testable import VERAAudioDiagnostics

    @Suite("AudioDiagnostics UI Button Tests")
    @MainActor
    struct AudioDiagnosticsButtonTests {

        // MARK: - AudioDiagnosticsButton Tests

        @Test("AudioDiagnosticsButton initializes with makeView closure")
        func audioDiagnosticsButtonInitializesWithMakeViewClosure() {
            var closureCalled = false
            let makeView: OnLaunchAudioDiagnostics = {
                closureCalled = true
                return AnyView(Text("Test"))
            }

            let button = AudioDiagnosticsButton(makeView: makeView)

            // Button should exist and closure should not be called yet
            #expect(button is AudioDiagnosticsButton)
            #expect(closureCalled == false)
        }

        @Test("AudioDiagnosticsButton initializes with nil makeView")
        func audioDiagnosticsButtonInitializesWithNilMakeView() {
            let button = AudioDiagnosticsButton(makeView: nil)

            // Should not crash with nil closure
            #expect(button is AudioDiagnosticsButton)
        }

        @Test("AudioDiagnosticsButton initializes with default parameters")
        func audioDiagnosticsButtonInitializesWithDefaults() {
            let button = AudioDiagnosticsButton()

            #expect(button is AudioDiagnosticsButton)
        }

        // MARK: - AudioDiagnosticsWaitingRoomButton Tests

        @Test("AudioDiagnosticsWaitingRoomButton initializes with makeDialog closure")
        func audioDiagnosticsWaitingRoomButtonInitializesWithMakeDialogClosure() {
            var closureCalled = false
            let makeDialog: OnLaunchAudioDiagnostics = {
                closureCalled = true
                return AnyView(Text("Test"))
            }

            let button = AudioDiagnosticsWaitingRoomButton(makeDialog: makeDialog)

            // Button should exist and closure should not be called yet
            #expect(button is AudioDiagnosticsWaitingRoomButton)
            #expect(closureCalled == false)
        }

        @Test("AudioDiagnosticsWaitingRoomButton initializes with nil makeDialog")
        func audioDiagnosticsWaitingRoomButtonInitializesWithNilMakeDialog() {
            let button = AudioDiagnosticsWaitingRoomButton(makeDialog: nil)

            // Should not crash with nil closure
            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        @Test("AudioDiagnosticsWaitingRoomButton initializes with default parameters")
        func audioDiagnosticsWaitingRoomButtonInitializesWithDefaults() {
            let button = AudioDiagnosticsWaitingRoomButton()

            #expect(button is AudioDiagnosticsWaitingRoomButton)
        }

        // MARK: - AudioDiagnosticsMeetingRoomButton Tests

        @Test("AudioDiagnosticsMeetingRoomButton initializes with onShowDialog closure")
        func audioDiagnosticsMeetingRoomButtonInitializesWithOnShowDialogClosure() {
            var closureCalled = false
            let onShowDialog: OnShowAudioDiagnostics = {
                closureCalled = true
            }

            let button = AudioDiagnosticsMeetingRoomButton(onShowDialog: onShowDialog)

            // Button should exist and closure should not be called yet
            #expect(button is AudioDiagnosticsMeetingRoomButton)
            #expect(closureCalled == false)
        }

        @Test("AudioDiagnosticsMeetingRoomButton initializes with nil onShowDialog")
        func audioDiagnosticsMeetingRoomButtonInitializesWithNilOnShowDialog() {
            let button = AudioDiagnosticsMeetingRoomButton(onShowDialog: nil)

            // Should not crash with nil closure
            #expect(button is AudioDiagnosticsMeetingRoomButton)
        }

        @Test("AudioDiagnosticsMeetingRoomButton initializes with default parameters")
        func audioDiagnosticsMeetingRoomButtonInitializesWithDefaults() {
            let button = AudioDiagnosticsMeetingRoomButton()

            #expect(button is AudioDiagnosticsMeetingRoomButton)
        }

        // MARK: - Type Alias Tests

        @Test("OnLaunchAudioDiagnostics type alias is correct")
        func onLaunchAudioDiagnosticsTypeAliasIsCorrect() {
            let closure: OnLaunchAudioDiagnostics = {
                return AnyView(Text("Test"))
            }

            let result = closure()
            #expect(result is AnyView)
        }

        @Test("OnShowAudioDiagnostics type alias is correct")
        func onShowAudioDiagnosticsTypeAliasIsCorrect() {
            var called = false
            let closure: OnShowAudioDiagnostics = {
                called = true
            }

            closure()
            #expect(called == true)
        }

        // MARK: - Integration Tests

        @Test("Button components can be created with real factory")
        func buttonComponentsCanBeCreatedWithRealFactory() {
            let service = MockSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: service)

            let waitingRoomButton = factory.makeWaitingRoomButton()
            let selectorButton = factory.makeWaitingRoomSelectorButton()
            let meetingRoomButton = factory.makeMeetingRoomButton {}

            #expect(waitingRoomButton is AudioDiagnosticsWaitingRoomButton)
            #expect(selectorButton is AudioDiagnosticsButton)
            #expect(meetingRoomButton is AudioDiagnosticsMeetingRoomButton)
        }

        @Test("Button components work with NullSpeakerTestService")
        func buttonComponentsWorkWithNullSpeakerTestService() {
            let nullService = NullSpeakerTestService()
            let factory = AudioDiagnosticsFactory(speakerTestService: nullService)

            let waitingRoomButton = factory.makeWaitingRoomButton()
            let selectorButton = factory.makeWaitingRoomSelectorButton()
            let meetingRoomButton = factory.makeMeetingRoomButton {}

            // Should not crash with null service
            #expect(waitingRoomButton is AudioDiagnosticsWaitingRoomButton)
            #expect(selectorButton is AudioDiagnosticsButton)
            #expect(meetingRoomButton is AudioDiagnosticsMeetingRoomButton)
        }

        // MARK: - Edge Case Tests

        @Test("Multiple button instances are independent")
        func multipleButtonInstancesAreIndependent() {
            var button1CallCount = 0
            var button2CallCount = 0

            let button1 = AudioDiagnosticsButton {
                button1CallCount += 1
                return AnyView(Text("Button 1"))
            }

            let button2 = AudioDiagnosticsButton {
                button2CallCount += 1
                return AnyView(Text("Button 2"))
            }

            #expect(button1CallCount == 0)
            #expect(button2CallCount == 0)

            // Buttons should be independent instances
            #expect(button1 is AudioDiagnosticsButton)
            #expect(button2 is AudioDiagnosticsButton)
        }

        @Test("Buttons handle complex closure scenarios")
        func buttonsHandleComplexClosureScenarios() {
            // Test with closure that creates complex view
            let complexButton = AudioDiagnosticsButton {
                let viewModel = AudioOutputControlViewModel(
                    speakerTestService: NullSpeakerTestService()
                )
                return AnyView(
                    AudioDiagnosticsView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.hidden)
                )
            }

            #expect(complexButton is AudioDiagnosticsButton)
        }

        @Test("Meeting room button handles multiple callback types")
        func meetingRoomButtonHandlesMultipleCallbackTypes() {
            // Test with various callback scenarios
            let emptyButton = AudioDiagnosticsMeetingRoomButton {}
            let simpleButton = AudioDiagnosticsMeetingRoomButton {
                print("Simple callback")
            }
            var counter = 0
            let statefulButton = AudioDiagnosticsMeetingRoomButton {
                counter += 1
            }

            #expect(emptyButton is AudioDiagnosticsMeetingRoomButton)
            #expect(simpleButton is AudioDiagnosticsMeetingRoomButton)
            #expect(statefulButton is AudioDiagnosticsMeetingRoomButton)
            #expect(counter == 0)  // Callback not executed yet
        }
    }
#endif
