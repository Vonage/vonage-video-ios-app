//
//  Created by Vonage on 30/7/25.
//

import SwiftUI
import VERACommonUI

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
        )
    }
}
