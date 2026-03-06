//
//  Created by Vonage on 22/2/26.
//

import SwiftUI

/// General section content: reset-to-defaults action.
///
/// Returns `Section` blocks intended to be embedded inside a parent `Form`.
struct GeneralSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Button("Reset to Defaults".localized, role: .destructive) {
                viewModel.resetToDefaults()
            }
        } footer: {
            Text("Restores all settings to their default values.".localized)
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            GeneralSectionView(viewModel: .preview)
        }
        .preferredColorScheme(.dark)
    }
#endif
