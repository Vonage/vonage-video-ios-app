//
//  Created by Vonage on 19/06/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    public func opaquePresentationBackground(_ color: Color) -> some View {
        if #available(iOS 16.4, *) {
            presentationBackground(color)
        } else {
            background(color)
        }
    }
}
