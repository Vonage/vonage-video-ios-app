//
//  Created by Vonage on 18/6/26.
//

import SwiftUI

public struct BottomBarInlineButton: View {
    private let image: Image
    private let isActive: Bool
    private let accessibilityIdentifier: String?
    private let accessory: BottomBarButtonAccessory?
    private let action: () -> Void

    public init(
        image: Image,
        isActive: Bool = false,
        accessibilityIdentifier: String? = nil,
        accessory: BottomBarButtonAccessory? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.image = image
        self.isActive = isActive
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessory = accessory
        self.action = action
    }

    public var body: some View {
        OngoingActivityControlImageButton(
            isActive: isActive,
            image: image,
            accessibilityIdentifier: accessibilityIdentifier,
            accessory: accessory,
            action: action
        )
    }
}
