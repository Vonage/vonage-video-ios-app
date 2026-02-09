//
//  Created by Vonage on 5/2/26.
//

import Foundation

/// Represents a single caption from a speaker in a video call
public struct CaptionItem: Identifiable, Equatable {
    /// Unique identifier for the caption
    public let id: UUID

    /// Name of the person speaking
    public let speakerName: String

    /// The caption text
    public let text: String

    /// When the caption was created
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        speakerName: String,
        text: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.speakerName = speakerName
        self.text = text
        self.timestamp = timestamp
    }
}
