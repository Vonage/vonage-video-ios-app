//
//  Created by Vonage on 24/04/2026.
//

import Foundation
import SwiftUI
import Testing
import VERACommonUI

@testable import VERAMeetingRoom

@Suite("BottomBar.calculateMaxExtraButtons Tests")
struct BottomBarCalculateMaxExtraButtonsTests {

    // MARK: - Helper

    private func createBottomBar(
        allowMicrophoneControl: Bool = true,
        allowCameraControl: Bool = true,
        showParticipantList: Bool = true,
        isParticipantsListPresented: Bool = false
    ) -> BottomBar {
        .init(
            isMicEnabled: true,
            isCameraEnabled: true,
            isParticipantsListPresented: isParticipantsListPresented,
            participantsCount: 5,
            allowMicrophoneControl: allowMicrophoneControl,
            allowCameraControl: allowCameraControl,
            showParticipantList: showParticipantList,
            currentLayout: .activeSpeaker,
            actions: .init()
        )
    }

    @Test("BottomBarButton stores shared inline and overflow presentation")
    @MainActor
    func bottomBarButtonStoresSharedPresentation() {
        var didTap = false
        let item = BottomBarActionItem(
            id: "support-button",
            label: "Support",
            accessibilityIdentifier: "support-accessibility-id",
            image: Image(systemName: "questionmark.circle"),
            isActive: true,
            action: {
                didTap = true
            }
        )
        let button = BottomBarButton(item)

        #expect(button.id == "support-button")
        #expect(button.label == "Support")
        #expect(button.accessibilityIdentifier == "support-accessibility-id")
        #expect(button.isActive)
        #expect(button.accessory == nil)

        button.action()
        #expect(didTap)
    }

    @Test("BottomBarButton can override active presentation state")
    @MainActor
    func bottomBarButtonCanOverrideActivePresentationState() {
        let item = BottomBarActionItem(
            id: "sheet-button",
            label: "Sheet",
            image: .init(systemName: "square"),
            isActive: false,
            action: {}
        )

        let button = BottomBarButton(item, isActive: true)

        #expect(button.isActive)
    }

    // MARK: - All Features Enabled

    @Test("Returns 0 when width equals base buttons width")
    func zeroExtraButtonsWhenExactFit() {
        let bar = createBottomBar()

        let buttonWidth = BottomBarConstants.buttonWidth  // 50
        let spacing = BottomBarConstants.buttonSpacing  // 8
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2  // 16

        // All features enabled: 5 base buttons (Mic + Camera + Layout + Participants + EndCall)
        let baseButtonsCount = 5
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        let result = bar.calculateMaxExtraButtons(availableWidth: baseButtonsWidth)
        #expect(result == 0)
    }

    @Test("Returns 1 when width fits exactly one extra button")
    func oneExtraButtonWhenFitsExactly() {
        let bar = createBottomBar()

        let buttonWidth = BottomBarConstants.buttonWidth  // 50
        let spacing = BottomBarConstants.buttonSpacing  // 8
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2  // 16

        // All features enabled: 5 base buttons
        let baseButtonsCount = 5
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        // Add space for exactly one extra button
        let widthForOneExtra = baseButtonsWidth + buttonWidth + spacing

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForOneExtra)
        #expect(result == 1)
    }

    @Test("Returns multiple extra buttons when sufficient width available")
    func multipleExtraButtonsWithLargeWidth() {
        let bar = createBottomBar()

        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        // All features enabled: 5 base buttons
        let baseButtonsCount = 5
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        // Add space for 5 extra buttons
        let widthForFiveExtras = baseButtonsWidth + CGFloat(5) * (buttonWidth + spacing)

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForFiveExtras)
        #expect(result == 5)
    }

    @Test("Returns 0 when available width is very small")
    func zeroExtraButtonsWithTinyWidth() {
        let bar = createBottomBar()

        let result = bar.calculateMaxExtraButtons(availableWidth: 10)
        #expect(result == 0)
    }

    @Test("Returns 0 for negative remaining width")
    func zeroExtraButtonsWhenInsufficientWidth() {
        let bar = createBottomBar()

        let result = bar.calculateMaxExtraButtons(availableWidth: 100)
        #expect(result == 0)
    }

    // MARK: - Minimal Features Enabled

    @Test("Calculates correctly with only required buttons (no mic, camera, participants)")
    func minimalFeaturesCalculation() {
        let bar = createBottomBar(
            allowMicrophoneControl: false,
            allowCameraControl: false,
            showParticipantList: false
        )

        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        // Only 2 base buttons: Layout + EndCall
        let baseButtonsCount = 2
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        // With minimal features, same width should fit more extra buttons
        let widthForThreeExtras = baseButtonsWidth + CGFloat(3) * (buttonWidth + spacing)

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForThreeExtras)
        #expect(result == 3)
    }

    // MARK: - Partial Features Enabled

    @Test("Calculates correctly with only microphone control enabled")
    func onlyMicrophoneControlEnabled() {
        let bar = createBottomBar(
            allowMicrophoneControl: true,
            allowCameraControl: false,
            showParticipantList: false
        )

        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        // 3 base buttons: Mic + Layout + EndCall
        let baseButtonsCount = 3
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        let widthForTwoExtras = baseButtonsWidth + CGFloat(2) * (buttonWidth + spacing)

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForTwoExtras)
        #expect(result == 2)
    }

    @Test("Calculates correctly with only camera control enabled")
    func onlyCameraControlEnabled() {
        let bar = createBottomBar(
            allowMicrophoneControl: false,
            allowCameraControl: true,
            showParticipantList: false
        )

        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        // 3 base buttons: Camera + Layout + EndCall
        let baseButtonsCount = 3
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        let widthForTwoExtras = baseButtonsWidth + CGFloat(2) * (buttonWidth + spacing)

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForTwoExtras)
        #expect(result == 2)
    }

    @Test("Calculates correctly with only participant list enabled")
    func onlyParticipantListEnabled() {
        let bar = createBottomBar(
            allowMicrophoneControl: false,
            allowCameraControl: false,
            showParticipantList: true
        )

        let buttonWidth = BottomBarConstants.buttonWidth
        let spacing = BottomBarConstants.buttonSpacing
        let horizontalPadding = BottomBarConstants.containerPaddingHorizontal * 2

        // 3 base buttons: Participants + Layout + EndCall
        let baseButtonsCount = 3
        let baseButtonsWidth =
            CGFloat(baseButtonsCount) * buttonWidth + CGFloat(baseButtonsCount - 1) * spacing + horizontalPadding

        let widthForTwoExtras = baseButtonsWidth + CGFloat(2) * (buttonWidth + spacing)

        let result = bar.calculateMaxExtraButtons(availableWidth: widthForTwoExtras)
        #expect(result == 2)
    }

    // MARK: - Edge Cases

    @Test("Never returns negative values")
    func neverReturnsNegative() {
        let bar = createBottomBar()

        let result = bar.calculateMaxExtraButtons(availableWidth: 0)
        #expect(result >= 0)
    }

    @Test("Returns 0 for extremely large width deficit")
    func largeWidthDeficit() {
        let bar = createBottomBar()

        let result = bar.calculateMaxExtraButtons(availableWidth: 50)
        #expect(result >= 0)
    }

    @Test("Handles very large available width")
    func veryLargeAvailableWidth() {
        let bar = createBottomBar()

        let result = bar.calculateMaxExtraButtons(availableWidth: 2000)
        #expect(result > 0)
    }

    // MARK: - Consistency Tests

    @Test("Result increases with available width")
    func resultIncreasesWithWidth() {
        let bar = createBottomBar()

        let smallWidth = 200.0
        let largeWidth = 600.0

        let smallResult = bar.calculateMaxExtraButtons(availableWidth: smallWidth)
        let largeResult = bar.calculateMaxExtraButtons(availableWidth: largeWidth)

        #expect(largeResult >= smallResult)
    }

    @Test("Minimal features fit more extra buttons than full features")
    func minimalFeaturesMoreExtraButtons() {
        let fullFeaturesBar = createBottomBar(
            allowMicrophoneControl: true,
            allowCameraControl: true,
            showParticipantList: true
        )

        let minimalFeaturesBar = createBottomBar(
            allowMicrophoneControl: false,
            allowCameraControl: false,
            showParticipantList: false
        )

        let testWidth = 400.0

        let fullResult = fullFeaturesBar.calculateMaxExtraButtons(availableWidth: testWidth)
        let minimalResult = minimalFeaturesBar.calculateMaxExtraButtons(availableWidth: testWidth)

        #expect(minimalResult >= fullResult)
    }
}
