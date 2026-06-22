//
//  Created by Vonage on 19/06/2026.
//

import SwiftUI
import Testing

@testable import VERACommonUI

#if os(macOS)
    import AppKit
    private typealias HostingController<Content: View> = NSHostingController<Content>
#else
    import UIKit
    private typealias HostingController<Content: View> = UIHostingController<Content>
#endif

@Suite("Bottom bar item tests")
struct BottomBarItemTests {

    @Test("BottomBarActionItem stores default metadata")
    @MainActor
    func bottomBarActionItemStoresDefaultMetadata() {
        var didPerformAction = false
        let item = BottomBarActionItem(
            label: "Support",
            accessibilityIdentifier: "support-accessibility-id",
            image: Image(systemName: "questionmark.circle"),
            action: {
                didPerformAction = true
            }
        )

        #expect(item.id == "Support")
        #expect(item.label == "Support")
        #expect(item.accessibilityIdentifier == "support-accessibility-id")
        #expect(item.isActive == false)
        #expect(item.accessory == nil)
        #expect(item.overflowSelectionBehavior == .performActionBeforeDismiss)
        let isGridItem: Bool = {
            if case .gridItem = item.overflowPresentation { return true }
            return false
        }()
        #expect(isGridItem)

        item.performAction()

        #expect(didPerformAction)
    }

    @Test("BottomItemPresentable provides default overflow metadata")
    @MainActor
    func bottomItemPresentableProvidesDefaultOverflowMetadata() {
        let item = TestBottomItemPresentable()

        let isGridItem: Bool = {
            if case .gridItem = item.overflowPresentation { return true }
            return false
        }()
        #expect(isGridItem)
        #expect(item.overflowSelectionBehavior == .performActionBeforeDismiss)
    }

    @Test("BottomBarActionItem stores override metadata")
    @MainActor
    func bottomBarActionItemStoresOverrideMetadata() {
        let accessory = BottomBarButtonAccessory(
            placement: .topTrailing,
            allowsHitTesting: true
        ) {
            Text("Accessory")
        }
        let item = BottomBarActionItem(
            id: "sheet-button",
            label: "Sheet",
            image: Image(systemName: "square"),
            isActive: true,
            accessory: accessory,
            overflowPresentation: .headerContent {
                AnyView(Text("Header"))
            },
            overflowSelectionBehavior: .dismissBeforeAction,
            action: {}
        )

        #expect(item.isActive)
        #expect(item.accessory?.allowsHitTesting == true)
        _ = item.accessory?.content()
        #expect(item.overflowSelectionBehavior == .dismissBeforeAction)
        var didBuildHeaderContent = false
        if case .headerContent(let content) = item.overflowPresentation {
            _ = content()
            didBuildHeaderContent = true
        }
        #expect(didBuildHeaderContent)
    }

    @Test("BottomBarMenuItem renders inactive state")
    @MainActor
    func bottomBarMenuItemRendersInactiveState() {
        let accessory = BottomBarButtonAccessory(placement: .topTrailing) {
            Text("1")
        }
        let item = BottomBarMenuItem(
            image: Image(systemName: "message"),
            label: "Chat",
            accessibilityIdentifier: "chat-button",
            accessory: accessory,
            action: {}
        )

        _ = item.body
        host(item)
    }

    @Test("BottomBarMenuItem renders active state")
    @MainActor
    func bottomBarMenuItemRendersActiveState() {
        let accessory = BottomBarButtonAccessory(placement: .topTrailing) {
            Text("1")
        }
        let item = BottomBarMenuItem(
            image: Image(systemName: "gearshape"),
            label: "Settings",
            isActive: true,
            accessibilityIdentifier: "settings-button",
            accessory: accessory,
            action: {}
        )

        _ = item.body
        host(item)
    }

    @Test("BottomBarMenuItem exposes captions accessibility identifier and action")
    @MainActor
    func bottomBarMenuItemExposesCaptionsAccessibilityIdentifierAndAction() {
        var didTap = false
        let item = BottomBarMenuItem(
            image: Image(systemName: "captions.bubble"),
            label: "Captions",
            accessibilityIdentifier: "captions-toggle-button"
        ) {
            didTap = true
        }

        _ = item.body
        host(item)
        item.performAction()

        #expect(didTap)
    }

    @Test("BottomBarInlineButton renders active state and accessory")
    @MainActor
    func bottomBarInlineButtonRendersActiveStateAndAccessory() {
        let accessory = BottomBarButtonAccessory(placement: .topTrailing) {
            Text("1")
        }
        let item = BottomBarInlineButton(
            image: Image(systemName: "ellipsis.circle"),
            isActive: true,
            accessibilityIdentifier: "more-options-button",
            accessory: accessory
        ) {}

        _ = item.body
        host(item)
    }

    @Test("Ongoing activity control button renders")
    @MainActor
    func ongoingActivityControlButtonRenders() {
        let defaultActionItem = OngoingActivityControlButton(
            isActive: false,
            iconName: "ellipsis.circle"
        )
        let item = OngoingActivityControlButton(
            isActive: true,
            iconName: "ellipsis.circle"
        ) {}

        _ = defaultActionItem.body
        _ = item.body
        host(defaultActionItem)
        host(item)
    }

    @Test("Ongoing activity control image button renders")
    @MainActor
    func ongoingActivityControlImageButtonRenders() {
        let defaultActionItem = OngoingActivityControlImageButton(
            isActive: false,
            image: Image(systemName: "captions.bubble")
        )
        let accessory = BottomBarButtonAccessory(placement: .topTrailing) {
            Text("1")
        }
        let item = OngoingActivityControlImageButton(
            isActive: true,
            image: Image(systemName: "captions.bubble"),
            accessibilityIdentifier: "captions-toggle-button",
            accessory: accessory
        ) {}

        _ = defaultActionItem.body
        _ = item.body
        host(defaultActionItem)
        host(item)
    }

    @Test("Opaque presentation background modifier renders")
    @MainActor
    func opaquePresentationBackgroundModifierRenders() {
        host(Text("Sheet").opaquePresentationBackground(.red))
    }

    @Test("Drag indicator renders")
    @MainActor
    func dragIndicatorRenders() {
        let item = DragIndicatorView()

        _ = item.body
        host(item)
    }

    @Test("Bottom bar accessory modifier renders all placements")
    @MainActor
    func bottomBarAccessoryModifierRendersAllPlacements() {
        host(
            Text("Base")
                .bottomBarButtonAccessory(
                    BottomBarButtonAccessory(placement: .topTrailing) {
                        Text("Top")
                    }
                )
        )
        host(
            Text("Base")
                .bottomBarButtonAccessory(
                    BottomBarButtonAccessory(placement: .center, allowsHitTesting: true) {
                        Text("Center")
                    }
                )
        )
        host(
            Text("Base")
                .bottomBarButtonAccessory(
                    BottomBarButtonAccessory(placement: .hiddenInteractionLayer) {
                        Text("Hidden")
                    }
                )
        )
        host(Text("Base").bottomBarButtonAccessory(nil))
    }

    @discardableResult
    @MainActor
    private func host<V: View>(_ view: V) -> HostingController<V> {
        let controller = HostingController(rootView: view)
        controller.view.frame = CGRect(x: 0, y: 0, width: 220, height: 120)
        #if os(macOS)
            controller.view.layoutSubtreeIfNeeded()
        #else
            controller.view.layoutIfNeeded()
        #endif
        return controller
    }
}

@MainActor
private struct TestBottomItemPresentable: BottomItemPresentable {
    let id = "test-item"
    let label = "Test"
    let accessibilityIdentifier: String? = nil
    let image = Image(systemName: "circle")
    let isActive = false
    let accessory: BottomBarButtonAccessory? = nil

    func performAction() {}
}
