//
//  Created by Vonage on 6/2/26.
//

import SwiftUI

public struct CaptionsScreenButton: View {

    @ObservedObject var viewModel: CaptionsButtonViewModel

    public init(viewModel: CaptionsButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CaptionsButton(
            state: viewModel.state,
            action: viewModel.onTap
        )
    }
}
