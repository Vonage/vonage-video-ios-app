//
//  Created by Vonage on 16/4/26.
//

import Combine
import Foundation
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@testable import VERAMeetingRoomSDK

@Suite("BottomBarButtonsAssembler tests")
struct BottomBarButtonsAssemblerTests {

    private static let testBaseURL = URL(string: "https://api.example.com")!

    @Test("Returns empty buttons when no features are enabled")
    @MainActor
    func emptyFeaturesProducesNoButtons() {
        let container = makeContainer(enabledFeatures: [])
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: []
        )

        let buttons = assembler.buildButtons()
        #expect(buttons.isEmpty)
    }

    @Test("Chat feature produces one button")
    @MainActor
    func chatFeatureProducesOneButton() {
        let features: Set<MeetingRoomFeature> = [.chat]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let buttons = assembler.buildButtons()
        #expect(buttons.count == 1)
        #expect(buttons.first?.id == "chat-button")
        #expect(buttons.first?.label == "Chat")
        #expect(buttons.first?.isActive == false)
    }

    @Test("Chat button is active when chat sheet is presented")
    @MainActor
    func chatButtonIsActiveWhenChatSheetIsPresented() {
        let features: Set<MeetingRoomFeature> = [.chat]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        assembler.setChatPresented(true)
        let button = assembler.buildButtons().first

        #expect(button?.id == "chat-button")
        #expect(button?.isActive == true)
    }

    @Test("Settings feature produces one button")
    @MainActor
    func settingsFeatureProducesOneButton() {
        let features: Set<MeetingRoomFeature> = [.settings]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let buttons = assembler.buildButtons()
        #expect(buttons.count == 1)
        #expect(buttons.first?.id == "settings-button")
        #expect(buttons.first?.label == String(localized: "Settings"))
    }

    @Test("Settings button is active when settings sheet is presented")
    @MainActor
    func settingsButtonIsActiveWhenSettingsSheetIsPresented() {
        let features: Set<MeetingRoomFeature> = [.settings]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        assembler.setSettingsPresented(true)
        let button = assembler.buildButtons().first

        #expect(button?.id == "settings-button")
        #expect(button?.isActive == true)
    }

    @Test("Feedback feature produces one button from presenter")
    @MainActor
    func feedbackFeatureProducesOneButton() {
        let features: Set<MeetingRoomFeature> = [.feedback]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let buttons = assembler.buildButtons()
        #expect(buttons.count == 1)
        #expect(buttons.first?.id == "feedback-button")
        #expect(buttons.first?.label == String(localized: "Feedback"))
        #expect(buttons.first?.isActive == false)
    }

    @Test("Feedback button is active when feedback sheet is presented")
    @MainActor
    func feedbackButtonIsActiveWhenFeedbackSheetIsPresented() {
        let features: Set<MeetingRoomFeature> = [.feedback]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        assembler.setFeedbackFormPresented(true)
        let button = assembler.buildButtons().first

        #expect(button?.id == "feedback-button")
        #expect(button?.isActive == true)
    }

    @Test("Screen share feature produces one button")
    @MainActor
    func screenShareFeatureProducesOneButton() {
        let features: Set<MeetingRoomFeature> = [.screenShare]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let buttons = assembler.buildButtons()
        #expect(buttons.count == 1)
        #expect(buttons.first?.id == "screen-share-button")
        #expect(buttons.first?.label == String(localized: "Share Screen"))
        #expect(buttons.first?.accessory != nil)
    }

    @Test("Archiving button requires pre-created view model")
    @MainActor
    func archivingButtonRequiresViewModel() {
        let features: Set<MeetingRoomFeature> = [.archiving]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // Without setting archiveButtonViewModel, no archiving button is produced
        let buttons = assembler.buildButtons()
        #expect(buttons.isEmpty)
    }

    @Test("Background effects button requires pre-created view model")
    @MainActor
    func backgroundEffectsButtonRequiresViewModel() {
        let features: Set<MeetingRoomFeature> = [.backgroundEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // Without setting backgroundEffectButtonViewModel, no effect button is produced
        let buttons = assembler.buildButtons()
        #expect(buttons.isEmpty)
    }

    @Test("Background effects button is active when effects sheet is presented")
    @MainActor
    func backgroundEffectsButtonIsActiveWhenEffectsSheetIsPresented() {
        let features: Set<MeetingRoomFeature> = [.backgroundEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let viewModel = container.backgroundEffectFactory.makeViewModel {
            MockVERAPublisher()
        }
        assembler.videoEffectsViewModel = viewModel

        assembler.setEffectsPresented(true)
        let button = assembler.buildButtons().first

        #expect(button?.id == "effects-button")
        #expect(button?.isActive == true)
    }

    @Test("Captions button requires pre-created view model")
    @MainActor
    func captionsButtonRequiresViewModel() {
        let features: Set<MeetingRoomFeature> = [.captions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // Without setting captionsButtonViewModel, no captions button is produced
        let buttons = assembler.buildButtons()
        #expect(buttons.isEmpty)
    }

    @Test("Reactions button requires pre-created view model")
    @MainActor
    func reactionsButtonRequiresViewModel() {
        let features: Set<MeetingRoomFeature> = [.reactions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // Without setting emojiButtonContainerViewModel, no reactions button is produced
        let buttons = assembler.buildButtons()
        #expect(buttons.isEmpty)
    }

    @Test("Reactions feature produces one button from presenter when view model exists")
    @MainActor
    func reactionsFeatureProducesOneButton() {
        let features: Set<MeetingRoomFeature> = [.reactions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        assembler.emojiButtonContainerViewModel = container.reactionsFactory.makeEmojiButton().viewModel

        let buttons = assembler.buildButtons()

        #expect(buttons.count == 1)
        #expect(buttons.first?.id == "reactions-button")
        #expect(buttons.first?.label == String(localized: "Reactions"))
        #expect(buttons.first?.isActive == false)
    }

    @Test("Reactions button is active when picker overlay is presented")
    @MainActor
    func reactionsButtonIsActiveWhenPickerOverlayIsPresented() {
        let features: Set<MeetingRoomFeature> = [.reactions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        assembler.emojiButtonContainerViewModel = container.reactionsFactory.makeEmojiButton().viewModel

        assembler.setReactionsPickerPresented(true)
        let button = assembler.buildButtons().first

        #expect(button?.id == "reactions-button")
        #expect(button?.isActive == true)
    }

    @Test("Multiple features produce multiple buttons")
    @MainActor
    func multipleFeaturesProduceMultipleButtons() {
        let features: Set<MeetingRoomFeature> = [.chat, .screenShare, .settings]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let buttons = assembler.buildButtons()
        // chat + screenShare + settings = 3 buttons (no VM-dependent features)
        #expect(buttons.count == 3)
    }

    @Test("Audio effects button is lazily created")
    @MainActor
    func audioEffectsButtonIsLazilyCreated() {
        let features: Set<MeetingRoomFeature> = [.audioEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // Audio effects creates its view model lazily in buildButtons
        let buttons = assembler.buildButtons()
        #expect(buttons.count == 1)
        #expect(buttons.first?.label == String(localized: "Noise Suppression"))
        #expect(assembler.meetingNoiseSuppressionButtonViewModel != nil)
    }

    @Test("Audio effects button is active when noise suppression is enabled")
    @MainActor
    func audioEffectsButtonIsActiveWhenNoiseSuppressionIsEnabled() {
        let features: Set<MeetingRoomFeature> = [.audioEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        _ = assembler.buildButtons()
        assembler.meetingNoiseSuppressionButtonViewModel?.state = .enabled
        let button = assembler.buildButtons().first

        #expect(button?.id == "noise-suppression-button")
        #expect(button?.isActive == true)
    }

    @Test("Archive button uses presenter metadata in idle state")
    @MainActor
    func archiveButtonUsesPresenterMetadataInIdleState() {
        let features: Set<MeetingRoomFeature> = [.archiving]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let (_, viewModel) = container.archivingFactory.makeArchivingButton { _ in }
        assembler.archiveButtonViewModel = viewModel

        let button = assembler.buildButtons().first

        #expect(button?.id == "archive-button")
        #expect(button?.label == String(localized: "Start Recording"))
        #expect(button?.accessibilityIdentifier == "archiving-start-recording-button")
        #expect(button?.isActive == false)
    }

    @Test("Archive button uses presenter metadata in archiving state")
    @MainActor
    func archiveButtonUsesPresenterMetadataInArchivingState() {
        let features: Set<MeetingRoomFeature> = [.archiving]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let (_, viewModel) = container.archivingFactory.makeArchivingButton { _ in }
        viewModel.state = .archiving("archive-123")
        assembler.archiveButtonViewModel = viewModel

        let button = assembler.buildButtons().first

        #expect(button?.id == "archive-button")
        #expect(button?.label == String(localized: "Stop Recording"))
        #expect(button?.accessibilityIdentifier == "archiving-stop-recording-button")
        #expect(button?.isActive == true)
    }

    @Test("buttonsDidChange emits when archive button state changes")
    @MainActor
    func buttonsDidChangeEmitsWhenArchiveButtonStateChanges() {
        let features: Set<MeetingRoomFeature> = [.archiving]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let (_, viewModel) = container.archivingFactory.makeArchivingButton { _ in }
        assembler.archiveButtonViewModel = viewModel
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        viewModel.state = .archiving("archive-123")

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("buttonsDidChange emits when captions button state changes")
    @MainActor
    func buttonsDidChangeEmitsWhenCaptionsButtonStateChanges() {
        let features: Set<MeetingRoomFeature> = [.captions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let (_, viewModel) = container.captionsFactory.makeCaptionsButton()
        assembler.captionsButtonViewModel = viewModel
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        viewModel.state = .enabled("captions-123")

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("buttonsDidChange emits when reactions picker presentation changes")
    @MainActor
    func buttonsDidChangeEmitsWhenReactionsPickerPresentationChanges() {
        let features: Set<MeetingRoomFeature> = [.reactions]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        assembler.setReactionsPickerPresented(true)

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("buttonsDidChange emits when sheet presentation changes")
    @MainActor
    func buttonsDidChangeEmitsWhenSheetPresentationChanges() {
        let features: Set<MeetingRoomFeature> = [.chat]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        assembler.setChatPresented(true)

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("buttonsDidChange emits when audio effects state changes")
    @MainActor
    func buttonsDidChangeEmitsWhenAudioEffectsStateChanges() {
        let features: Set<MeetingRoomFeature> = [.audioEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        _ = assembler.buildButtons()
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        assembler.meetingNoiseSuppressionButtonViewModel?.state = .enabled

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("buttonsDidChange emits when injected audio effects view model state changes")
    @MainActor
    func buttonsDidChangeEmitsWhenInjectedAudioEffectsViewModelStateChanges() {
        let features: Set<MeetingRoomFeature> = [.audioEffects]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )
        let viewModel = container.audioEffectsFactory.makeMeetingNoiseSuppressionButton().viewModel
        assembler.meetingNoiseSuppressionButtonViewModel = viewModel
        var didEmitUpdate = false
        let cancellable = assembler.buttonsDidChange.sink {
            didEmitUpdate = true
        }

        viewModel.state = .enabled

        #expect(didEmitUpdate)
        cancellable.cancel()
    }

    @Test("rebuildButtons rebuilds current feature buttons")
    @MainActor
    func rebuildButtonsRebuildsCurrentFeatureButtons() {
        let features: Set<MeetingRoomFeature> = [.chat]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        let initialButtons = assembler.buildButtons()
        let rebuiltButtons = assembler.rebuildButtons()

        #expect(rebuiltButtons.count == initialButtons.count)
        #expect(rebuiltButtons.first?.label == initialButtons.first?.label)
    }

    // MARK: - Helpers

    private func makeContainer(
        enabledFeatures: Set<MeetingRoomFeature>
    ) -> MeetingRoomSDKContainer {
        MeetingRoomSDKContainer(
            baseURL: Self.testBaseURL,
            enabledFeatures: enabledFeatures)
    }
}
