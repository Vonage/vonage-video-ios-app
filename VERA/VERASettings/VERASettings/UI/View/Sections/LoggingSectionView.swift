//
//  Created by Vonage on 21/05/2026.
//

import SwiftUI

/// Logging section content: SDK logging toggle, level, and log sharing action.
struct LoggingSectionView: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Section {
            Toggle("Enable SDK Logging".localized, isOn: $viewModel.isLoggingEnabled)

            Picker("Log Level".localized, selection: $viewModel.sdkLogLevel) {
                ForEach(SDKLogLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .disabled(!viewModel.isLoggingEnabled)

            #if canImport(UIKit)
                Button("Send Logs".localized) {
                    viewModel.sendLogs()
                }
                .disabled(!viewModel.isLoggingEnabled)
            #endif
        } header: {
            Text("Logging".localized)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    "When enabled, Vonage SDK logs are saved to files that can be shared for troubleshooting."
                        .localized)
                if viewModel.loggingSettingsChanged {
                    Text(
                        "Please close and reopen the app for SDK logging changes to take effect."
                            .localized
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
    #Preview {
        Form {
            LoggingSectionView(viewModel: .previewWithLoggingEnabled)
        }
        .preferredColorScheme(.dark)
    }
#endif
