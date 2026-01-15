//
//  Created by Vonage on 14/1/26.
//

import SwiftUI

public struct ArchiveScreenButton: View {

    @ObservedObject var viewModel: ArchiveButtonViewModel

    public init(viewModel: ArchiveButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ArchiveButton(state: viewModel.state, action: viewModel.onTap)
    }
}
