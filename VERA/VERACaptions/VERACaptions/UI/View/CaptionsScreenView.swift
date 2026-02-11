//
//  Created by Vonage on 10/2/26.
//

import SwiftUI

public struct CaptionsScreenView: View {

    @ObservedObject var viewModel: CaptionsViewModel

    public init(viewModel: CaptionsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if !viewModel.captions.isEmpty {
            CaptionsView(captions: viewModel.captions)
        }
    }
}
