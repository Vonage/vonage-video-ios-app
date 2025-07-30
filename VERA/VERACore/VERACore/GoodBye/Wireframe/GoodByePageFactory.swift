//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

public class GoodByePageFactory {
    
    public init() {}
    
    public func make(
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) -> some View {
        GoodByeViewScreen(
            viewModel: .init(),
            onReenter: onReenter,
            onReturnToLanding: onReturnToLanding)
    }
}
