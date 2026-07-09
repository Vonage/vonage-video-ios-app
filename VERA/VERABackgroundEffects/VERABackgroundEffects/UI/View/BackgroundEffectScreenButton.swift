//
//  Created by Vonage on 26/1/26.
//

import SwiftUI
import VERACommonUI

public struct BackgroundEffectScreenButton: View {
    @Environment(\.meetingRoomTheme) private var theme

    @ObservedObject var viewModel: VideoEffectsViewModel

    public init(viewModel: VideoEffectsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        BackgroundEffectButton(
            image: viewModel.selectedEffect.image,
            action: { viewModel.isSheetPresented = true }
        )
        .sheet(isPresented: $viewModel.isSheetPresented) {
            VideoEffectsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .opaquePresentationBackground(theme.background)
        }
    }
}
