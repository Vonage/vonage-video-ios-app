//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

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
        ).alert(item: $viewModel.error) { alertItem in
            Alert(
                title: Text(alertItem.title),
                message: Text(alertItem.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
