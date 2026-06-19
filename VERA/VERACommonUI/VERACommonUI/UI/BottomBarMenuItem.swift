//
//  Created by Vonage on 18/6/26.
//

import SwiftUI

public struct BottomBarMenuItem: View {
    @Environment(\.meetingRoomTheme) private var theme

    private var foregroundColor: Color {
        isActive ? theme.onPrimary : theme.secondary
    }

    private let image: Image
    private let label: String
    private let isActive: Bool
    private let accessibilityIdentifier: String?
    private let accessory: BottomBarButtonAccessory?
    private let action: () -> Void

    public init(
        image: Image,
        label: String,
        isActive: Bool = false,
        accessibilityIdentifier: String? = nil,
        accessory: BottomBarButtonAccessory? = nil,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.label = label
        self.isActive = isActive
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessory = accessory
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                image
                    .font(.title3)
                    .foregroundStyle(foregroundColor)
                Text(label)
                    .font(.callout)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(foregroundColor)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive ? theme.primary : theme.background)
            )
            .overlay {
                if !isActive {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .if(accessibilityIdentifier != nil) { view in
            view.accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
        .bottomBarButtonAccessory(accessory)
    }
}
