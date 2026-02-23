//
//  Created by Vonage on 23/02/2026.
//

import Foundation
import SwiftUI
import VERADomain

extension CaptionItem {
    /// Converts this domain caption into a display-ready ``UICaptionItem``.
    ///
    /// Resolves the speaker name to the localised "You" when ``isMe`` is `true`,
    /// formats the text as a bold-name + regular-body `AttributedString`,
    /// and builds a VoiceOver-friendly accessibility label.
    ///
    /// - Returns: A new ``UICaptionItem`` ready for display.
    public func toUICaptionItem() -> UICaptionItem {
        let name =
            isMe
            ? String(localized: "You", bundle: .veraCaptions)
            : speakerName

        var boldPart = AttributedString(name + ": ")
        boldPart.font = .system(.footnote, design: .default).bold()
        var regularPart = AttributedString(text)
        regularPart.font = .system(.footnote, design: .default)

        let localizedFormat = String(localized: "user_say", bundle: .veraCaptions)

        return UICaptionItem(
            id: id,
            text: boldPart + regularPart,
            accessibilityLabel: String(format: localizedFormat, name, text),
            isMe: isMe,
            timestamp: timestamp
        )
    }
}
