//
//  Created by Vonage on 2/4/26.
//

import Foundation
import Testing
import VERADomain

@Suite("CaptionItem tests")
struct CaptionItemTests {

    @Test("CaptionItem stores properties correctly")
    func captionItemProperties() {
        let timestamp = Date()
        let caption = CaptionItem(
            id: "caption-1",
            speakerName: "Alice",
            text: "Hello everyone",
            isMe: false,
            timestamp: timestamp)

        #expect(caption.id == "caption-1")
        #expect(caption.speakerName == "Alice")
        #expect(caption.text == "Hello everyone")
        #expect(caption.isMe == false)
        #expect(caption.timestamp == timestamp)
    }

    @Test("CaptionItem defaults isMe to false")
    func captionItemDefaultIsMe() {
        let caption = CaptionItem(speakerName: "Bob", text: "Hi")

        #expect(caption.isMe == false)
    }

    @Test("CaptionItem equality with same properties")
    func captionItemEquality() {
        let timestamp = Date()
        let caption1 = CaptionItem(
            id: "same-id",
            speakerName: "Alice",
            text: "Hello",
            isMe: true,
            timestamp: timestamp)
        let caption2 = CaptionItem(
            id: "same-id",
            speakerName: "Alice",
            text: "Hello",
            isMe: true,
            timestamp: timestamp)

        #expect(caption1 == caption2)
    }

    @Test("CaptionItem inequality with different id")
    func captionItemInequalityById() {
        let timestamp = Date()
        let caption1 = CaptionItem(
            id: "id-1",
            speakerName: "Alice",
            text: "Hello",
            timestamp: timestamp)
        let caption2 = CaptionItem(
            id: "id-2",
            speakerName: "Alice",
            text: "Hello",
            timestamp: timestamp)

        #expect(caption1 != caption2)
    }

    @Test("CaptionItem with isMe set to true")
    func captionItemIsMe() {
        let caption = CaptionItem(
            speakerName: "Me",
            text: "My message",
            isMe: true)

        #expect(caption.isMe == true)
    }

    @Test("CaptionItem generates unique id by default")
    func captionItemGeneratesUniqueId() {
        let caption1 = CaptionItem(speakerName: "A", text: "X")
        let caption2 = CaptionItem(speakerName: "A", text: "X")

        #expect(caption1.id != caption2.id)
    }
}
