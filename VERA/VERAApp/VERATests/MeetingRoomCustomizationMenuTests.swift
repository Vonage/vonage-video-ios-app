//
//  Created by Vonage on 30/6/26.
//

import SwiftUI
import Testing

@testable import VERA

@MainActor
@Suite("Meeting room customization menu tests")
struct MeetingRoomCustomizationMenuTests {

    @Test("Root menu builds its body")
    func rootMenuBuildsBody() {
        let sut = MeetingRoomCustomizationMenu(provider: MeetingRoomCustomizationProvider())

        _ = sut.body
    }

    @Test("Bottom bar menu builds its body")
    func bottomBarMenuBuildsBody() {
        let sut = MeetingRoomCustomizationBottomBarMenu(provider: MeetingRoomCustomizationProvider())

        _ = sut.body
    }

    @Test("Buttons screen builds empty state")
    func buttonsScreenBuildsEmptyState() {
        let sut = MeetingRoomCustomizationBottomBarButtonsView(provider: MeetingRoomCustomizationProvider())

        _ = sut.body
    }

    @Test("Buttons screen builds configured state")
    func buttonsScreenBuildsConfiguredState() {
        let provider = MeetingRoomCustomizationProvider()
        provider.addButton()
        provider.bottomBarButtons()[0].action()

        let sut = MeetingRoomCustomizationBottomBarButtonsView(provider: provider)

        _ = sut.body
    }

    @Test("Add button row builds its body")
    func addButtonRowBuildsBody() {
        let sut = MeetingRoomCustomizationAddButtonRow(
            title: "Add dialog button",
            systemImage: MeetingRoomCustomizationButtonKind.dialog.systemImageName,
            action: {}
        )

        _ = sut.body
    }

    @Test("Add button row executes configured action")
    func addButtonRowExecutesConfiguredAction() {
        var actionCount = 0
        let sut = MeetingRoomCustomizationAddButtonRow(
            title: "Add overlay button",
            systemImage: MeetingRoomCustomizationButtonKind.overlay.systemImageName
        ) {
            actionCount += 1
        }

        sut.action()

        #expect(actionCount == 1)
    }

    @Test("Custom bar screen builds and binding updates provider")
    func customBarScreenBuildsAndBindingUpdatesProvider() {
        let provider = MeetingRoomCustomizationProvider()
        let sut = MeetingRoomCustomizationBottomBarCustomBarView(provider: provider)

        _ = sut.body
        sut.customBottomBarBinding.wrappedValue = true
        #expect(provider.isCustomBottomBarEnabled)

        sut.customBottomBarBinding.wrappedValue = false
        #expect(!provider.isCustomBottomBarEnabled)
    }

    @Test("Custom bar binding keeps redundant updates quiet")
    func customBarBindingKeepsRedundantUpdatesQuiet() {
        let provider = MeetingRoomCustomizationProvider()
        let sut = MeetingRoomCustomizationBottomBarCustomBarView(provider: provider)
        var updateCount = 0
        let cancellable = provider.updates.sink {
            updateCount += 1
        }

        sut.customBottomBarBinding.wrappedValue = false

        #expect(updateCount == 0)
        cancellable.cancel()
    }
}
