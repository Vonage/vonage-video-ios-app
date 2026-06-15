//
//  Created by Vonage on 01/06/2026.
//

import SwiftUI
import VERABackgroundEffects

struct BackgroundEffectsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showEffects: Bool
    let videoEffectsViewModel: VideoEffectsViewModel?

    func body(content: Content) -> some View {
        if isEnabled, let viewModel = videoEffectsViewModel {
            content
                .sheet(isPresented: $showEffects) {
                    VideoEffectsSheet(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                }
        } else {
            content
        }
    }
}
