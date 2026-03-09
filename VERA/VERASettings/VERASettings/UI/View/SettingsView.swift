//
//  Created by Vonage on 25/2/26.
//

import SwiftUI

/// Main view for the Settings feature.
public struct SettingsView: View {
    @ObservedObject private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        // TODO: Implement view
        Text("Settings")
    }
}
