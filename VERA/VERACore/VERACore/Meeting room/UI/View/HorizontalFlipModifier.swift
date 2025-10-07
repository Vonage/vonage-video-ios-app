//
//  Created by Vonage on 3/10/25.
//

import SwiftUI

struct HorizontalFlipModifier: ViewModifier {
    let shouldFlip: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: shouldFlip ? -1 : 1, y: 1)
    }
}

extension View {
    func horizontallyFlipped(_ shouldFlip: Bool = false) -> some View {
        modifier(HorizontalFlipModifier(shouldFlip: shouldFlip))
    }
}
