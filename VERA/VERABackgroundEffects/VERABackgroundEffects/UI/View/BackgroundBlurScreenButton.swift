//
//  Created by Vonage on 26/1/26.
//

import SwiftUI
import VERACommonUI

public struct BackgroundBlurScreenButton: View {

    @ObservedObject var viewModel: BackgroundBlurButtonViewModel

    public init(viewModel: BackgroundBlurButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        BackgroundBlurButton(
            image: viewModel.currentBlurLevel.image,
            action: viewModel.onTap)
    }
}
