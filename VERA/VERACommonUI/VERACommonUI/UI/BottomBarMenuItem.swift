//
//  Created by Vonage on 18/6/26.
//

import SwiftUI

public struct BottomBarMenuItem: View {
    @Environment(\.meetingRoomTheme) private var theme

    private let image: Image
    private let label: String
    private let accessibilityIdentifier: String?
    private let action: () -> Void

    public init(
        image: Image,
        label: String,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                image
                    .tint(theme.textSecondary)
                Text(label)
                    .tint(theme.textSecondary)
            }
        }
        .if(accessibilityIdentifier != nil) { view in
            view.accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
    }
}
