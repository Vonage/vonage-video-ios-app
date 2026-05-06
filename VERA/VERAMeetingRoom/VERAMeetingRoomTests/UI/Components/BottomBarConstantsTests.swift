//
//  Created by Vonage on 24/04/2026.
//

import Foundation
import Testing

@testable import VERAMeetingRoom

@Suite("BottomBarConstants Tests")
struct BottomBarConstantsTests {

    // MARK: - Computed Properties

    @Test("Content height includes button height plus vertical padding on both sides")
    func contentHeightCalculation() {
        let expected = BottomBarConstants.buttonHeight + (BottomBarConstants.containerPaddingVertical * 2)
        #expect(BottomBarConstants.contentHeight == expected)
    }

    @Test("Total height includes content height plus bottom padding")
    func totalHeightCalculation() {
        let expected = BottomBarConstants.contentHeight + BottomBarConstants.containerPaddingBottom
        #expect(BottomBarConstants.totalHeight == expected)
    }

    // MARK: - Backward Compatibility

    @Test("Button width alias equals button height")
    func buttonWidthEqualsButtonHeight() {
        #expect(BottomBarConstants.buttonWidth == BottomBarConstants.buttonHeight)
    }
}
