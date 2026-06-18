//
//  Created by Vonage on 18/6/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    public func bottomBarButtonAccessory(_ accessory: BottomBarButtonAccessory?) -> some View {
        if let accessory {
            switch accessory.placement {
            case .topTrailing:
                overlay(alignment: .topTrailing) {
                    accessory.content()
                        .allowsHitTesting(accessory.allowsHitTesting)
                }
            case .center:
                overlay(alignment: .center) {
                    accessory.content()
                        .allowsHitTesting(accessory.allowsHitTesting)
                }
            case .hiddenInteractionLayer:
                overlay {
                    accessory.content()
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .allowsHitTesting(accessory.allowsHitTesting)
                }
            }
        } else {
            self
        }
    }
}
