//
//  Created by Vonage on 21/05/2026.
//

import SwiftUI

/// Coordinator that observes the ``SettingsViewModel`` and maps its state
/// to bindings consumed by ``LoggingSectionView`` (stateless presentation).
///
/// Follows the Screen / View two-tier pattern used elsewhere in VERASettings
/// (see ``StatisticsSectionScreen`` for reference).
struct LoggingSectionScreen: View {

    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        LoggingSectionView(
            isLoggingEnabled: $viewModel.isLoggingEnabled,
            sdkLogLevel: $viewModel.sdkLogLevel,
            loggingSettingsChanged: viewModel.loggingSettingsChanged,
            onSendLogs: { viewModel.sendLogs() }
        )
    }
}

// MARK: - LoggingSectionView

/// Pure presentation component for the logging section.
/// Contains no ViewModel references — receives only bindings and values.
struct LoggingSectionView: View {

    @Binding var isLoggingEnabled: Bool
    @Binding var sdkLogLevel: SDKLogLevel
    var loggingSettingsChanged: Bool
    var onSendLogs: (() -> Void)?

    var body: some View {
        Section {
            Toggle("Enable SDK Logging".localized, isOn: $isLoggingEnabled)

            Picker("Log Level".localized, selection: $sdkLogLevel) {
                ForEach(SDKLogLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .disabled(!isLoggingEnabled)

            #if canImport(UIKit)
                if let onSendLogs {
                    Button("Send Logs".localized) {
                        onSendLogs()
                    }
                    .disabled(!isLoggingEnabled)
                }
            #endif
        } header: {
            Text("Logging".localized)
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    "When enabled, Vonage SDK logs are saved to files that can be shared for troubleshooting."
                        .localized)
                if loggingSettingsChanged {
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
    #Preview("Via Screen") {
        Form {
            LoggingSectionScreen(viewModel: .previewWithLoggingEnabled)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Pure View - Enabled") {
        Form {
            LoggingSectionView(
                isLoggingEnabled: .constant(true),
                sdkLogLevel: .constant(.debug),
                loggingSettingsChanged: false,
                onSendLogs: {}
            )
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Pure View - Changed") {
        Form {
            LoggingSectionView(
                isLoggingEnabled: .constant(true),
                sdkLogLevel: .constant(.warn),
                loggingSettingsChanged: true,
                onSendLogs: {}
            )
        }
        .preferredColorScheme(.dark)
    }
#endif
