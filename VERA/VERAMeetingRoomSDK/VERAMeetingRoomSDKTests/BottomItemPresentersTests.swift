//
//  Created by Vonage on 19/06/2026.
//

import Testing
import VERACommonUI
import VERAReactions

@testable import VERAMeetingRoomSDK

@Suite("Bottom item presenters tests")
struct BottomItemPresentersTests {

    @Test("Settings presenter exposes metadata and action")
    @MainActor
    func settingsPresenterExposesMetadataAndAction() {
        var didShowSettings = false
        let sut = SettingsBottomItemPresenter {
            didShowSettings = true
        }

        #expect(sut.id == "settings-button")
        #expect(sut.label == String(localized: "Settings"))
        #expect(sut.accessibilityIdentifier != nil)
        #expect(sut.isActive == false)
        #expect(sut.accessory == nil)
        #expect(sut.overflowSelectionBehavior == .dismissBeforeAction)
        if case .gridItem = sut.overflowPresentation {
            #expect(true)
        } else {
            #expect(false)
        }

        sut.performAction()

        #expect(didShowSettings)
    }

    @Test("Feedback presenter exposes metadata and action")
    @MainActor
    func feedbackPresenterExposesMetadataAndAction() {
        var didShowFeedback = false
        let sut = FeedbackBottomItemPresenter {
            didShowFeedback = true
        }

        #expect(sut.id == "feedback-button")
        #expect(sut.label == String(localized: "Feedback"))
        #expect(sut.accessibilityIdentifier == nil)
        #expect(sut.isActive == false)
        #expect(sut.accessory == nil)
        #expect(sut.overflowSelectionBehavior == .dismissBeforeAction)

        sut.performAction()

        #expect(didShowFeedback)
    }

    @Test("Reactions presenter exposes inline and overflow metadata")
    @MainActor
    func reactionsPresenterExposesInlineAndOverflowMetadata() {
        var didShowPicker = false
        let viewModel = EmojiButtonContainerViewModel(
            sendReactionUseCase: SendReactionUseCaseSpy()
        )
        let sut = ReactionsBottomItemPresenter(
            isPickerPresented: true,
            viewModel: viewModel
        ) {
            didShowPicker = true
        }

        #expect(sut.id == "reactions-button")
        #expect(sut.label == String(localized: "Reactions"))
        #expect(sut.accessibilityIdentifier == nil)
        #expect(sut.isActive)
        #expect(sut.accessory == nil)
        #expect(sut.overflowSelectionBehavior == .performActionBeforeDismiss)
        if case .headerContent(let content) = sut.overflowPresentation {
            _ = content()
            #expect(true)
        } else {
            #expect(false)
        }

        sut.performAction()

        #expect(didShowPicker)
    }

    @Test("Screen share presenter exposes metadata and hidden accessory")
    @MainActor
    func screenSharePresenterExposesMetadataAndHiddenAccessory() {
        let sut = ScreenShareBottomItemPresenter(extensionId: "com.vonage.test.BroadcastExtension")

        #expect(sut.id == "screen-share-button")
        #expect(sut.label == String(localized: "Share Screen"))
        #expect(sut.accessibilityIdentifier == nil)
        #expect(sut.isActive == false)
        #expect(sut.overflowSelectionBehavior == .performActionBeforeDismiss)
        #expect(sut.accessory?.placement == .hiddenInteractionLayer)
        if case .gridItem = sut.overflowPresentation {
            #expect(true)
        } else {
            #expect(false)
        }

        _ = sut.accessory?.content()
        sut.performAction()
    }
}

private final class SendReactionUseCaseSpy: SendReactionUseCase {
    func callAsFunction(_ emoji: String) throws {}
}
