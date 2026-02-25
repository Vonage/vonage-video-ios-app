//
//  Created by Vonage on 25/2/26.
//

import Foundation

/// View model for SettingsView.
@MainActor
public final class SettingsViewModel: ObservableObject {
    public let settingsUseCase: SettingsUseCase

    public init(settingsUseCase: SettingsUseCase) {
        self.settingsUseCase = settingsUseCase
    }
}
