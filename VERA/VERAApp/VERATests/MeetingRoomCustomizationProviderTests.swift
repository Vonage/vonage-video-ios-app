//
//  Created by Vonage on 29/6/26.
//

import Combine
import SwiftUI
import Testing
import VERAMeetingRoom

@testable import VERA

@MainActor
@Suite("Meeting room customization provider tests")
struct MeetingRoomCustomizationProviderTests {

    @Test("Initial bottom bar buttons is empty")
    func initialBottomBarButtonsIsEmpty() {
        let sut = MeetingRoomCustomizationProvider()

        #expect(sut.bottomBarButtons().isEmpty)
    }

    @Test("Button kinds expose labels and system images")
    func buttonKindsExposeLabelsAndSystemImages() {
        #expect(MeetingRoomCustomizationButtonKind.allCases.map(\.label) == ["Toggle", "Dialog", "Overlay", "Sheet"])
        #expect(
            MeetingRoomCustomizationButtonKind.allCases.map(\.systemImageName) == [
                "switch.2",
                "exclamationmark.bubble.fill",
                "rectangle.on.rectangle",
                "rectangle.bottomhalf.inset.filled",
            ])
    }

    @Test("Button item exposes stable display metadata")
    func buttonItemExposesStableDisplayMetadata() {
        let item = MeetingRoomCustomizationButtonItem(
            id: "custom-7",
            label: "Dialog 7",
            kind: .dialog,
            isActive: true)

        #expect(item.accessibilityIdentifier == "meeting-room-custom-button-custom-7")
        #expect(item.systemImageName == "exclamationmark.bubble.fill")
    }

    @Test("Add button appends button and emits update")
    func addButtonAppendsButtonAndEmitsUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.addButton()

        #expect(sut.bottomBarButtons().map(\.label) == ["Toggle 1"])
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Add presentation buttons append typed buttons")
    func addPresentationButtonsAppendTypedButtons() {
        let sut = MeetingRoomCustomizationProvider()

        sut.addDialogButton()
        sut.addOverlayButton()
        sut.addSheetButton()

        #expect(sut.items.map(\.kind) == [.dialog, .overlay, .sheet])
        #expect(sut.bottomBarButtons().map(\.label) == ["Dialog 1", "Overlay 2", "Sheet 3"])
    }

    @Test("Add typed buttons emit updates and use SDK bottom bar")
    func addTypedButtonsEmitUpdatesAndUseSDKBottomBar() {
        let sut = MeetingRoomCustomizationProvider()
        sut.setCustomBottomBarEnabled(true)
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.addToggleButton()
        sut.addDialogButton()
        sut.addOverlayButton()
        sut.addSheetButton()

        #expect(!sut.isCustomBottomBarEnabled)
        #expect(sut.items.map(\.kind) == [.toggle, .dialog, .overlay, .sheet])
        #expect(sut.bottomBarContent(context: makeBottomBarContext()) == nil)
        #expect(updateCount == 4)
        cancellable.cancel()
    }

    @Test("Add button uses SDK bottom bar")
    func addButtonUsesSDKBottomBar() {
        let sut = MeetingRoomCustomizationProvider()
        sut.setCustomBottomBarEnabled(true)
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.addButton()

        #expect(!sut.isCustomBottomBarEnabled)
        #expect(sut.bottomBarContent(context: makeBottomBarContext()) == nil)
        #expect(sut.bottomBarButtons().map(\.label) == ["Toggle 1"])
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Remove last button removes latest button and emits update")
    func removeLastButtonRemovesLatestButtonAndEmitsUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        sut.addButton()
        sut.addButton()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.removeLastButton()

        #expect(sut.bottomBarButtons().map(\.label) == ["Toggle 1"])
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Remove last button does not emit update when empty")
    func removeLastButtonDoesNotEmitUpdateWhenEmpty() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.removeLastButton()

        #expect(sut.bottomBarButtons().isEmpty)
        #expect(updateCount == 0)
        cancellable.cancel()
    }

    @Test("Clear buttons removes all buttons and emits update")
    func clearButtonsRemovesAllButtonsAndEmitsUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        sut.addButton()
        sut.addButton()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.clearButtons()

        #expect(sut.bottomBarButtons().isEmpty)
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Clear buttons does not emit update when empty")
    func clearButtonsDoesNotEmitUpdateWhenEmpty() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.clearButtons()

        #expect(sut.bottomBarButtons().isEmpty)
        #expect(updateCount == 0)
        cancellable.cancel()
    }

    @Test("Generated button action toggles active state and emits update")
    func generatedButtonActionTogglesActiveStateAndEmitsUpdate() async {
        let sut = MeetingRoomCustomizationProvider()
        sut.addToggleButton()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        let button = sut.bottomBarButtons()[0]
        #expect(!button.isActive)
        button.action()
        await Task.yield()

        let updatedButton = sut.bottomBarButtons()[0]
        #expect(updatedButton.isActive)
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Missing button action does not emit update")
    func missingButtonActionDoesNotEmitUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.handleButtonAction(id: "missing")

        #expect(updateCount == 0)
        cancellable.cancel()
    }

    @Test("Presentation button action activates state and returns request")
    func presentationButtonActionActivatesStateAndReturnsRequest() async {
        let sut = MeetingRoomCustomizationProvider()
        sut.addSheetButton()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        let button = sut.bottomBarButtons()[0]
        button.action()
        let request = button.presentationRequest?()
        await Task.yield()

        #expect(sut.bottomBarButtons()[0].isActive)
        #expect(request?.style == .sheet)
        #expect(request?.sourceButtonId == "custom-1")
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Presentation dismiss deactivates source button")
    func presentationDismissDeactivatesSourceButton() async {
        let sut = MeetingRoomCustomizationProvider()
        sut.addOverlayButton()
        let button = sut.bottomBarButtons()[0]
        button.action()
        await Task.yield()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.dismissPresentation(sourceButtonId: "custom-1")

        #expect(!sut.bottomBarButtons()[0].isActive)
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Presentation dismiss ignores missing or inactive buttons")
    func presentationDismissIgnoresMissingOrInactiveButtons() {
        let sut = MeetingRoomCustomizationProvider()
        sut.addOverlayButton()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.dismissPresentation(sourceButtonId: "missing")
        sut.dismissPresentation(sourceButtonId: "custom-1")

        #expect(!sut.bottomBarButtons()[0].isActive)
        #expect(updateCount == 0)
        cancellable.cancel()
    }

    @Test("Presentation request on dismiss deactivates source button")
    func presentationRequestOnDismissDeactivatesSourceButton() async {
        let sut = MeetingRoomCustomizationProvider()
        sut.addDialogButton()
        let button = sut.bottomBarButtons()[0]
        button.action()
        let request = button.presentationRequest?()
        await Task.yield()

        request?.onDismiss?()

        #expect(!sut.bottomBarButtons()[0].isActive)
    }

    @Test("Generated presentation requests use configured styles")
    func generatedPresentationRequestsUseConfiguredStyles() {
        let sut = MeetingRoomCustomizationProvider()
        sut.addDialogButton()
        sut.addOverlayButton()
        sut.addSheetButton()

        let requests = sut.bottomBarButtons().compactMap { $0.presentationRequest?() }

        #expect(requests.map(\.style) == [.dialog, .overlay, .sheet])
    }

    @Test("Custom bottom bar starts disabled")
    func customBottomBarStartsDisabled() {
        let sut = MeetingRoomCustomizationProvider()

        #expect(!sut.isCustomBottomBarEnabled)
        #expect(sut.bottomBarContent(context: makeBottomBarContext()) == nil)
    }

    @Test("Enabling custom bottom bar emits update")
    func enablingCustomBottomBarEmitsUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.setCustomBottomBarEnabled(true)

        #expect(sut.isCustomBottomBarEnabled)
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Disabling custom bottom bar emits update")
    func disablingCustomBottomBarEmitsUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        sut.setCustomBottomBarEnabled(true)
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.setCustomBottomBarEnabled(false)

        #expect(!sut.isCustomBottomBarEnabled)
        #expect(updateCount == 1)
        cancellable.cancel()
    }

    @Test("Setting custom bottom bar to current value does not emit update")
    func settingCustomBottomBarToCurrentValueDoesNotEmitUpdate() {
        let sut = MeetingRoomCustomizationProvider()
        var updateCount = 0
        let cancellable = sut.updates.sink {
            updateCount += 1
        }

        sut.setCustomBottomBarEnabled(false)

        #expect(!sut.isCustomBottomBarEnabled)
        #expect(updateCount == 0)
        cancellable.cancel()
    }

    @Test("Custom bottom bar content is returned when enabled")
    func customBottomBarContentIsReturnedWhenEnabled() {
        let sut = MeetingRoomCustomizationProvider()

        sut.setCustomBottomBarEnabled(true)

        #expect(sut.bottomBarContent(context: makeBottomBarContext()) != nil)
    }

    @Test("Bottom bar buttons remain available when custom bar is enabled")
    func bottomBarButtonsRemainAvailableWhenCustomBarIsEnabled() {
        let sut = MeetingRoomCustomizationProvider()

        sut.addButton()
        sut.setCustomBottomBarEnabled(true)

        #expect(sut.bottomBarButtons().map(\.label) == ["Toggle 1"])
        #expect(sut.bottomBarContent(context: makeBottomBarContext(buttons: sut.bottomBarButtons())) != nil)
    }

    private func makeBottomBarContext(
        buttons: [BottomBarButton] = []
    ) -> MeetingRoomBottomBarContext {
        MeetingRoomBottomBarContext(
            state: .initial,
            actions: .init(),
            buttons: buttons,
            controls: makeBottomBarControls()
        )
    }

    private func makeBottomBarControls() -> MeetingRoomBottomBarControls {
        MeetingRoomBottomBarControls(
            microphone: makeControl(id: "microphone", image: "mic"),
            camera: makeControl(id: "camera", image: "video"),
            participants: makeControl(id: "participants", image: "person.2"),
            layout: makeControl(id: "layout", image: "rectangle.grid.2x2"),
            endCall: makeControl(id: "end-call", image: "phone.down.fill")
        )
    }

    private func makeControl(id: String, image: String) -> MeetingRoomBottomBarControl {
        MeetingRoomBottomBarControl(
            id: id,
            label: id,
            image: Image(systemName: image)
        ) {}
    }
}
