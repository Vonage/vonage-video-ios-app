//
//  Created by Vonage on 18/6/26.
//

import SwiftUI
import VERACommonUI

private enum BottomBarOverflowSheetConstants {
    static let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 16
    static let gridSpacing: CGFloat = 8
}

/// A bottom-sheet style overflow surface for meeting room bottom bar actions.
///
/// `BottomBarOverflowSheet` renders bottom bar actions that do not fit inline in
/// the meeting room bottom bar. Buttons using a header overflow presentation are
/// rendered above the grid, while regular actions are rendered as grid items.
/// Selection is delegated through `onSelect` so the presenting bottom bar keeps
/// control of dismissal and action timing.
struct BottomBarOverflowSheet: View {
    @Environment(\.meetingRoomTheme) private var theme

    private let buttons: [BottomBarButton]
    private let onSelect: (BottomBarButton) -> Void

    /// Creates an overflow sheet for the provided bottom bar buttons.
    ///
    /// - Parameters:
    ///   - buttons: The bottom bar buttons to render in the overflow sheet.
    ///   - onSelect: A callback invoked when a grid button is selected.
    init(
        buttons: [BottomBarButton],
        onSelect: @escaping (BottomBarButton) -> Void
    ) {
        self.buttons = buttons
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            DragIndicatorView()

            ScrollView {
                VStack(spacing: BottomBarOverflowSheetConstants.verticalPadding) {
                    ForEach(headerItems) { item in
                        item.content()
                    }

                    LazyVGrid(
                        columns: BottomBarOverflowSheetConstants.columns,
                        spacing: BottomBarOverflowSheetConstants.gridSpacing
                    ) {
                        ForEach(gridButtons) { button in
                            BottomBarMenuItem(
                                image: button.image,
                                label: button.label,
                                isActive: button.isActive,
                                accessibilityIdentifier: button.accessibilityIdentifier ?? button.id,
                                accessory: button.accessory
                            ) {
                                select(button)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, BottomBarOverflowSheetConstants.horizontalPadding)
            .padding(.vertical, BottomBarOverflowSheetConstants.verticalPadding)
        }
    }

    var gridButtons: [BottomBarButton] {
        buttons.filter { button in
            if case .gridItem = button.overflowPresentation {
                return true
            }
            return false
        }
    }

    var headerItems: [BottomBarOverflowHeaderItem] {
        buttons.compactMap { button in
            guard case .headerContent(let content) = button.overflowPresentation else {
                return nil
            }
            return .init(id: button.id, content: content)
        }
    }

    func select(_ button: BottomBarButton) {
        onSelect(button)
    }
}

struct BottomBarOverflowHeaderItem: Identifiable {
    let id: String
    let content: () -> AnyView
}

#Preview {
    BottomBarOverflowSheet(
        buttons: [
            .init(label: "Chat", image: Image(systemName: "message"), action: {}),
            .init(label: "Settings", image: Image(systemName: "gearshape"), isActive: true, action: {}),
            .init(label: "Recording", image: Image(systemName: "record.circle"), action: {}),
        ],
        onSelect: { _ in }
    )
    .padding()
    .background(.black)
}
