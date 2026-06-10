//
//  Created by Vonage on 10/06/2026.
//

import SwiftUI
import UIKit
import VERACommonUI

struct FeedbackKeyboardDoneToolbar: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                OutlinedButton(
                    text: Text(String(localized: "Done")),
                    color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
                    expandsToFillWidth: false,
                    fillColor: .white,
                    onAction: onDone
                )
            }
            .padding(.trailing, Layout.horizontalPadding)
            .padding(.vertical, Layout.verticalPadding)

            Color.clear.frame(height: Layout.keyboardSpacing)
        }
        .background(Color.clear)
    }

    private enum Layout {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let keyboardSpacing: CGFloat = 2
    }
}

enum FeedbackKeyboardDoneAccessory {
    static let estimatedHeight: CGFloat = 54

    static func makeHostingController(onDone: @escaping () -> Void) -> UIHostingController<FeedbackKeyboardDoneToolbar>
    {
        let hostingController = UIHostingController(rootView: FeedbackKeyboardDoneToolbar(onDone: onDone))
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: estimatedHeight
        )
        return hostingController
    }
}
