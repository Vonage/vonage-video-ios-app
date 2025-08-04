//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

struct GoodByeViewScreen: View {
    @ObservedObject var viewModel: GoodByeViewModel
    public let onReenter: () -> Void
    public let onReturnToLanding: () -> Void

    public init(
        viewModel: GoodByeViewModel,
        onReenter: @escaping () -> Void,
        onReturnToLanding: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onReenter = onReenter
        self.onReturnToLanding = onReturnToLanding
    }

    var body: some View {
        GoodByeView(
            archives: viewModel.archives,
            onReenter: onReenter,
            onReturnToLanding: onReturnToLanding
        )
    }
}
