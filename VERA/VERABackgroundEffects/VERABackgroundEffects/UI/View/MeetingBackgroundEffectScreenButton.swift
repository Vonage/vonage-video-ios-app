//
//  Created by Vonage on 30/1/26.
//

import Foundation
import SwiftUI
import VERACommonUI

public struct MeetingBackgroundEffectScreenButton: View {

    @ObservedObject var viewModel: VideoEffectsViewModel
    private let onShowEffects: (() -> Void)?

    public init(viewModel: VideoEffectsViewModel, onShowEffects: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onShowEffects = onShowEffects
    }

    public var body: some View {
        MeetingBackgroundEffectButton(
            image: viewModel.selectedEffect.image,
            action: { onShowEffects?() }
        )
    }
}
