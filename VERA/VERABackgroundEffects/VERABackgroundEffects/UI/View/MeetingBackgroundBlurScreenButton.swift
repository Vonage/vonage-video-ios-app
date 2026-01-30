//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI

public struct MeetingBackgroundBlurScreenButton: View {

    @ObservedObject var viewModel: BackgroundBlurButtonViewModel

    public init(viewModel: BackgroundBlurButtonViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        MeetingBackgroundBlurButton(
            image: viewModel.currentBlurLevel.image,
            action: viewModel.onTap)
    }
}
