//
//  Created by Vonage on 25/2/26.
//

import SwiftUI

/// Factory for creating the Settings feature components.
public class SettingsFactory {

    public func make() -> (view: some View, viewModel: SettingsViewModel) {
        let viewModel = SettingsViewModel(
            settingsUseCase: DefaultSettingsUseCase())
        return (make(viewModel: viewModel), viewModel)
    }

    public func make(
        viewModel: SettingsViewModel
    ) -> some View {
        SettingsView(viewModel: viewModel)
    }
}
