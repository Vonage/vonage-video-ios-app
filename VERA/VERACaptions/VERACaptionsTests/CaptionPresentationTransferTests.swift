//
//  Created by Vonage on 14/10/2026.
//

import Foundation
import SwiftUI
import Testing
import VERACaptions

@Suite("Caption presentation value transfer")
struct CaptionPresentationTransferTests {
    @Test("Styled captions retain text attributes, accessibility and identity after transfer")
    func styledCaptionsAcrossTasksAndActor() async throws {
        let storage = CaptionPresentationStorage()
        for isMe in [true, false] {
            let caption = makeCaption(isMe: isMe)
            await storage.update(await transfer(caption))
            let received = try #require(await storage.caption)
            #expect(received == caption)
            #expect(received.id == "caption/東京")
            #expect(received.text == caption.text)
            #expect(received.accessibilityLabel == "Zoë says: Hello 東京")
            #expect(received.isMe == isMe)
            #expect(received.timestamp == Date(timeIntervalSince1970: 1_000))
        }
    }

    @Test("Editing transferred accessibility text does not alter the original or stored caption")
    func captionCopiesRemainIndependent() async throws {
        let original = makeCaption(isMe: false)
        let storage = CaptionPresentationStorage()
        await storage.update(original)
        let edited = await Task.detached {
            var copy = original
            copy.accessibilityLabel = "Localized accessibility text"
            return copy
        }.value
        #expect(edited.accessibilityLabel == "Localized accessibility text")
        #expect(edited.text == original.text)
        #expect(original.accessibilityLabel == "Zoë says: Hello 東京")
        let stored = try #require(await storage.caption)
        #expect(stored == original)
    }

    private func transfer<Value: Sendable>(_ value: Value) async -> Value {
        await Task.detached { value }.value
    }

    private func makeCaption(isMe: Bool) -> UICaptionItem {
        var speaker = AttributedString("Zoë: ")
        speaker[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = .system(.footnote).bold()
        var message = AttributedString("Hello 東京")
        message[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = .system(.footnote)
        return .init(
            id: "caption/東京", text: speaker + message,
            accessibilityLabel: "Zoë says: Hello 東京", isMe: isMe,
            timestamp: Date(timeIntervalSince1970: 1_000)
        )
    }
}

private actor CaptionPresentationStorage {
    private(set) var caption: UICaptionItem?

    func update(_ value: UICaptionItem) {
        caption = value
    }
}
