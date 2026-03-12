//
//  Created by Vonage on 12/3/26.
//

import SwiftUI

/// Main view for the AudioEffects feature.
public struct AudioEffectsView: View {
    @ObservedObject private var viewModel: AudioEffectsViewModel

    public init(viewModel: AudioEffectsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Implement view
        Text("AudioEffects")
    }
}
