//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct GoodByeViewScreen<ContentView: View>: View {
    @ObservedObject var viewModel: GoodByeViewModel
    private let additionalContentView: () -> ContentView

    public init(
        viewModel: GoodByeViewModel,
        @ViewBuilder additionalContentView: @escaping () -> ContentView
    ) {
        self.viewModel = viewModel
        self.additionalContentView = additionalContentView
    }

    var body: some View {
        GoodByeView(
            additionalContentView: additionalContentView,
            onReenter: viewModel.onReenter,
            onReturnToLanding: viewModel.onReturnToLanding
        ).alert(item: $viewModel.error) { $0.view }
    }
}
