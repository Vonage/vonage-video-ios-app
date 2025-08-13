//
//  Created by Vonage on 13/8/25.
//

import Testing
import UIKit
import VERA
import VERACore

@Suite("PasteboardClipboard Tests")
struct PasteboardClipboardTests {

    @Test func copyReallyCopiesToUIPasterboard() async throws {
        let sut = makeSUT()
        let textToCopy = "Hello, World!"

        sut.copy(textToCopy)

        #expect(UIPasteboard.general.string == textToCopy)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> Clipboard {
        PasteboardClipboard()
    }
}
