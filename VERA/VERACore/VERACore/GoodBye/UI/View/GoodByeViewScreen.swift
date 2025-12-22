//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct GoodByeViewScreen: View {
    @ObservedObject var viewModel: GoodByeViewModel

    public init(viewModel: GoodByeViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GoodByeView(
            archives: viewModel.archives,
            onReenter: viewModel.onReenter,
            onReturnToLanding: viewModel.onReturnToLanding
        ).alert(item: $viewModel.error) { $0.view }
    }
}
