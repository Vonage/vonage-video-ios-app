//
//  Created by Vonage on 16/4/26.
//

import Foundation
import Testing
import VERADomain
import VERAMeetingRoom

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

        let buttons = assembler.buildButtons(.init(archivingState: .idle))
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

        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.count == 1)
        #expect(buttons.first?.label == "Chat")
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

        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.count == 1)
        #expect(buttons.first?.label == String(localized: "Settings"))
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

        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.count == 1)
        #expect(buttons.first?.label == String(localized: "Share Screen"))
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
        let buttons = assembler.buildButtons(.init(archivingState: .idle))
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
        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.isEmpty)
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
        let buttons = assembler.buildButtons(.init(archivingState: .idle))
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
        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.isEmpty)
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

        let buttons = assembler.buildButtons(.init(archivingState: .idle))
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
        let buttons = assembler.buildButtons(.init(archivingState: .idle))
        #expect(buttons.count == 1)
        #expect(buttons.first?.label == String(localized: "Noise Suppression"))
        #expect(assembler.meetingNoiseSuppressionButtonViewModel != nil)
    }

    @Test("rebuildButtons uses last state from buildButtons")
    @MainActor
    func rebuildButtonsUsesLastState() {
        let features: Set<MeetingRoomFeature> = [.chat]
        let container = makeContainer(enabledFeatures: features)
        let assembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: features
        )

        // First build with a specific state
        let initialButtons = assembler.buildButtons(.init(archivingState: .archiving("test-id")))
        // Rebuild should produce the same result using the cached state
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
