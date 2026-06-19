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

struct BottomBarOverflowSheet: View {
    private let buttons: [BottomBarButton]
    private let onSelect: (BottomBarButton) -> Void

    init(
        buttons: [BottomBarButton],
        onSelect: @escaping (BottomBarButton) -> Void
    ) {
        self.buttons = buttons
        self.onSelect = onSelect
    }

    var body: some View {
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
                            onSelect(button)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, BottomBarOverflowSheetConstants.horizontalPadding)
        .padding(.vertical, BottomBarOverflowSheetConstants.verticalPadding)
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
