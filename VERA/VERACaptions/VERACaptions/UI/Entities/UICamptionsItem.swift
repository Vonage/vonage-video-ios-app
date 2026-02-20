//
//  Created by Vonage on 19/02/2026.
//

import VERADomain
import Foundation

/// Represents a single caption from a speaker in a video call
public struct UICaptionItem: Identifiable, Equatable {
    /// Unique identifier for the caption
    public let id: UUID
    
    public let text: String
    
    public var accessibilityLabel: String
    
    /// When the caption was created
    public let timestamp: Date
    
    public init(
        caption: CaptionItem,
    ) {
        self.id = caption.id
        self.text = caption.speakerName + ": " + caption.text
        self.accessibilityLabel = "\(caption.speakerName) says: \(caption.text)"
        self.timestamp = caption.timestamp
    }
}

// MARK: - Preview Data

#if DEBUG
extension UICaptionItem {
    static let previewAlice = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Alice",
            text: "Hello everyone, welcome to the meeting!",
            timestamp: Date().addingTimeInterval(-6)
        )
    )

    static let previewBob = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Bob",
            text: "Sure, go ahead!",
            timestamp: Date().addingTimeInterval(-5)
        )
    )

    static let previewCharlie = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Charlie",
            text: "Sounds good to me!",
            timestamp: Date().addingTimeInterval(-4)
        )
    )

    static let previewDiana = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Diana",
            text: "I have a few items to cover.",
            timestamp: Date().addingTimeInterval(-3)
        )
    )

    static let previewAlice2 = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Alice",
            text: "Great, Diana please go first.",
            timestamp: Date().addingTimeInterval(-2)
        )
    )

    static let previewDiana2 = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Diana",
            text: "Thanks! The first thing is the new feature release.",
            timestamp: Date().addingTimeInterval(-1)
        )
    )

    static let previewLongText = UICaptionItem(
        caption: CaptionItem(
            speakerName: "Alice",
            text: "This is a really long caption that should wrap to multiple lines to demonstrate how the view handles text that exceeds the available width."
        )
    )
}
#endif
