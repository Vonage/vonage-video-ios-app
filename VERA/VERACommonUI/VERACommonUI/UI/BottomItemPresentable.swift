//
//  Created by Vonage on 18/6/26.
//

import SwiftUI

@MainActor
public protocol BottomItemPresentable {
    var id: String { get }
    var label: String { get }
    var accessibilityIdentifier: String? { get }
    var image: Image { get }
    var isActive: Bool { get }
    var accessory: BottomBarButtonAccessory? { get }

    func performAction()
}

@MainActor
public struct BottomBarActionItem: BottomItemPresentable {
    public let id: String
    public let label: String
    public let accessibilityIdentifier: String?
    public let image: Image
    public let isActive: Bool
    public let accessory: BottomBarButtonAccessory?

    private let action: () -> Void

    public init(
        id: String? = nil,
        label: String,
        accessibilityIdentifier: String? = nil,
        image: Image,
        isActive: Bool = false,
        accessory: BottomBarButtonAccessory? = nil,
        action: @escaping () -> Void
    ) {
        self.id = id ?? label
        self.label = label
        self.accessibilityIdentifier = accessibilityIdentifier
        self.image = image
        self.isActive = isActive
        self.accessory = accessory
        self.action = action
    }

    public func performAction() {
        action()
    }
}

public struct BottomBarButtonAccessory {
    public let placement: BottomBarButtonAccessoryPlacement
    public let content: () -> AnyView
    public let allowsHitTesting: Bool

    public init<Content: View>(
        placement: BottomBarButtonAccessoryPlacement,
        allowsHitTesting: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.placement = placement
        self.content = { AnyView(content()) }
        self.allowsHitTesting = allowsHitTesting
    }
}

public enum BottomBarButtonAccessoryPlacement {
    case topTrailing
    case center
    case hiddenInteractionLayer
}
