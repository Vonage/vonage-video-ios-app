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
}
