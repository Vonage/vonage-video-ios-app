//
//  Created by Vonage on 14/1/26.
//

import SwiftUI

public struct ArchiveScreenButton: View {

    var viewModel: ArchiveButtonViewModel

    public init(viewModel: ArchiveButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ArchiveButton(
            kind: viewModel.kind,
            state: viewModel.state,
            action: viewModel.onTap
        )
    }
}
